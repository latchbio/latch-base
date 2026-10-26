#!/usr/bin/env python3
"""Overwrite the CA bundles inside certifi, pip and botocore with the OS trust
store, for interpreters too old to install the patched releases. Python 3.6+.
"""
import os
import shutil
import sys

OS_BUNDLE = "/etc/ssl/certs/ca-certificates.crt"


def targets():
    try:
        import certifi

        yield "certifi", certifi.where()
    except ImportError:
        pass
    try:
        from pip._vendor import certifi as pip_certifi

        yield "pip._vendor.certifi", pip_certifi.where()
    except ImportError:
        pass
    for module_name in ("botocore", "awscli.botocore"):
        try:
            module = __import__(module_name, fromlist=["__file__"])
        except ImportError:
            continue
        yield module_name, os.path.join(os.path.dirname(module.__file__), "cacert.pem")


print("python %s (%s)" % (sys.version.split()[0], sys.executable))
for name, path in targets():
    if not os.path.isfile(path) or os.path.realpath(path) == OS_BUNDLE:
        print("  %-24s %s (skipped)" % (name, path))
        continue
    shutil.copyfile(OS_BUNDLE, path)
    print("  %-24s %s <- %s" % (name, path, OS_BUNDLE))
