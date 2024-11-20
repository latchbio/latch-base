SERIALIZED_PB_OUTPUT_DIR := /tmp/output

.PHONY: clean
clean:
	rm -rf $(SERIALIZED_PB_OUTPUT_DIR)/*

$(SERIALIZED_PB_OUTPUT_DIR): clean
	mkdir -p $(SERIALIZED_PB_OUTPUT_DIR)

.PHONY: serialize
serialize: $(SERIALIZED_PB_OUTPUT_DIR)
	pyflyte --config /root/flytekit.config serialize workflows -f $(SERIALIZED_PB_OUTPUT_DIR) --pkgs $(PACKAGES_TO_SERIALIZE)

.PHONY: register
register: serialize
	flytectl register file --admin.clientId ${FLYTE_CLIENT_ID} --admin.clientSecretLocation ${FLYTE_SECRET_PATH} --admin.endpoint ${FLYTE_ADMIN_ENDPOINT} --admin.insecure -p ${PROJECT} -d development --version ${VERSION} $(SERIALIZED_PB_OUTPUT_DIR)/*

.PHONY: test
test:
	pytest test.py
