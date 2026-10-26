#!/usr/bin/env python3
"""Fail if any trust store this interpreter can reach still contains a root
removed by DSA-6572-1. Bind-mounted into each image build and run under every
interpreter it ships; nothing is left in the image. Python 3.6+.
"""
import os
import ssl
import sys

BLOCKED = {"emSign ECC Root CA - G3", "AAA Certificate Services"}
OS_BUNDLE = "/etc/ssl/certs/ca-certificates.crt"
MIN_PIP = (26, 2, 2)  # 3.10+
MIN_CERTIFI = (2026, 10, 19)  # 3.7+


def version_tuple(text):
    parts = []
    for piece in text.split(".")[:3]:
        digits = "".join(ch for ch in piece if ch.isdigit())
        parts.append(int(digits or 0))
    return tuple(parts)


def is_os_bundle(path):
    return os.path.realpath(path) == os.path.realpath(OS_BUNDLE)


def summarize(ctx):
    certs = {}
    for cert in ctx.get_ca_certs():
        certs[(cert.get("issuer"), cert.get("serialNumber"))] = cert
    names = set()
    for cert in certs.values():
        for rdn in cert.get("subject", ()):
            for _key, value in rdn:
                names.add(value)
    return list(certs.values()), names


def roots(cafile):
    return summarize(ssl.create_default_context(cafile=cafile))


def default_roots():
    # note(anirudh): OpenSSL loads a hashed capath lazily, so get_ca_certs() can be empty while verification works
    ctx = ssl.create_default_context()
    certs, names = summarize(ctx)
    paths = ssl.get_default_verify_paths()
    where = ", ".join(p for p in (paths.cafile, paths.capath) if p)
    capath = os.environ.get(paths.openssl_capath_env or "SSL_CERT_DIR") or paths.capath
    if not certs and capath and os.path.isdir(capath):
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        for entry in sorted(os.listdir(capath)):
            path = os.path.join(capath, entry)
            if not os.path.isfile(path):
                continue
            try:
                ctx.load_verify_locations(cafile=path)
            except ssl.SSLError:
                pass
        certs, names = summarize(ctx)
        where = capath + " (read eagerly)"
    return certs, names, where


stores = [("os bundle", OS_BUNDLE)]
failures = []
have_certifi = False

try:
    import certifi

    have_certifi = True
    stores.append(("certifi %s" % certifi.__version__, certifi.where()))
    # note(anirudh): distro-patched certifi and pip return the OS bundle; only a vendored copy needs the fixed release
    if sys.version_info >= (3, 7) and not is_os_bundle(certifi.where()) and version_tuple(certifi.__version__) < MIN_CERTIFI:
        failures.append("certifi %s is older than %s" % (certifi.__version__, ".".join(map(str, MIN_CERTIFI))))
except ImportError:
    pass

try:
    import pip
    from pip._vendor import certifi as pip_certifi

    stores.append(("pip %s vendored certifi" % pip.__version__, pip_certifi.where()))
    if sys.version_info >= (3, 10) and not is_os_bundle(pip_certifi.where()) and version_tuple(pip.__version__) < MIN_PIP:
        failures.append("pip %s is older than %s" % (pip.__version__, ".".join(map(str, MIN_PIP))))
except ImportError:
    pass

# note(anirudh): botocore only reads its bundled cacert.pem when certifi is not importable
for module_name in () if have_certifi else ("botocore", "awscli.botocore"):
    try:
        module = __import__(module_name, fromlist=["__file__"])
    except ImportError:
        continue
    bundled = os.path.join(os.path.dirname(module.__file__), "cacert.pem")
    if os.path.exists(bundled):
        stores.append(("%s %s bundled cacert" % (module_name, module.__version__), bundled))

print("python %s (%s)" % (sys.version.split()[0], sys.executable))


def report(label, where, certs, names):
    bad = sorted(BLOCKED & names)
    print("  %-36s %-58s %4d roots%s" % (label, where, len(certs), "  BLOCKED: " + ", ".join(bad) if bad else ""))
    if not certs:
        failures.append("%s: no CA certificates loaded" % label)
    if bad:
        failures.append("%s still trusts %s" % (label, ", ".join(bad)))


certs, names, where = default_roots()
report("ssl defaults", where, certs, names)
for label, cafile in stores:
    certs, names = roots(cafile)
    report(label, cafile, certs, names)

if failures:
    print("CA check FAILED:", file=sys.stderr)
    for failure in failures:
        print("  - " + failure, file=sys.stderr)
    sys.exit(1)
print("  ok")
