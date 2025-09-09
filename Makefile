BUILD_DIR = build
TRIAL_BUILD_DIR = $(BUILD_DIR)/trial-divison

all: $(TRIAL_BUILD_DIR)/avx $(TRIAL_BUILD_DIR)/regular

$(TRIAL_BUILD_DIR)/avx: trial-division/main.asm Makefile
	@mkdir -p $(dir $@)
	fasm $< $@

$(TRIAL_BUILD_DIR)/regular: trial-division/regular.asm Makefile
	@mkdir -p $(dir $@)
	fasm $< $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
