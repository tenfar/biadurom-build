# build.prop.mk
# the default baidu prop

sub_space := \#

################# buildprop ############################

define getprop
if [ -f $(2) ]; then \
    awk -F= '/$(1)/{print $$2}' $(2); \
fi
endef

$(foreach property,$(BAIDU_PROPERTY_FOLLOW_BASE),\
    $(eval propValue := $(shell $(call getprop,$(property),$(BAIDU_SYSTEM)/build.prop))) \
    $(if $(propValue),\
        $(eval BAIDU_PROPERTY_OVERRIDES := $(filter-out $(property)=%,$(BAIDU_PROPERTY_OVERRIDES))) \
        $(eval BAIDU_PROPERTY_OVERRIDES += $(property)=$(propValue)) \
    ) \
)

BAIDU_PROPERTY_OVERRIDES := \
     $(call collapse-pairs, $(BAIDU_PROPERTY_OVERRIDES))

PROPERTY_REMOVE := $(remove_property)

PROPERTY_OVERRIDES := \
     $(strip $(override_property) $(BAIDU_PROPERTY_OVERRIDES))

PROPERTY_OVERRIDES := \
     $(subst $(space),$(sub_space),$(PROPERTY_OVERRIDES))

PROPERTY_OVERRIDES := \
     $(subst $(sub_space)=,=,$(PROPERTY_OVERRIDES))

PROPERTY_OVERRIDES := \
     $(subst =$(sub_space),=,$(PROPERTY_OVERRIDES))

PROPERTY_OVERRIDES := \
     $(shell echo $(PROPERTY_OVERRIDES) | sed -e 's/$(sub_space)\([^$(sub_space)]*\=\)/ \1/g')

PROPERTY_OVERRIDES := \
     $(call uniq-pairs-by-first-component,$(PROPERTY_OVERRIDES),=)

$(OUT_OBJ_SYSTEM)/baidu.build.prop:
	$(hide) mkdir -p $(OUT_OBJ_SYSTEM)
	$(hide) $(foreach line,$(PROPERTY_OVERRIDES), \
			echo ">>> overries property: `echo $(line) | sed 's/$(sub_space)/ /g'`"; \
			echo "$(line)" | sed 's/$(sub_space)/ /g' >> $@;)
	$(hide) $(foreach line,$(PROPERTY_REMOVE), \
			echo ">>> remove property: $(line)"; \
			echo "$(line)=delete" >> $@;)

.PHONY: build_prop
TARGET_FILES_SYSTEM += build_prop

ifeq ($(strip $(ROM_VERSION_TYPE)),)
ROM_VERSION_TYPE := $(shell $(call getprop,ro.version.type,$(BAIDU_SYSTEM)/build.prop))
export ROM_VERSION_TYPE
endif

ifeq ($(strip $(ROM_OFFICIAL_VERSION)),)
ROM_OFFICIAL_VERSION := $(shell $(call getprop,ro.official.version,$(BAIDU_SYSTEM)/build.prop))
export ROM_OFFICIAL_VERSION
endif

build_prop $(OUT_SYSTEM)/build.prop: $(OUT_OBJ_SYSTEM)/baidu.build.prop
build_prop $(OUT_SYSTEM)/build.prop: $(VENDOR_BUILD_PROP)
	$(hide) echo ">>> make build.prop"
	$(hide) echo ">>> make with version number: $(VERSION_NUMBER)"
	$(hide) mkdir -p $(OUT_SYSTEM)
	$(hide)	$(MAKE_BUILD_PROP) \
			-b $(OUT_OBJ_SYSTEM)/baidu.build.prop \
			-r $(VENDOR_BUILD_PROP) \
			$(if $(VERSION_NUMBER),-v $(VERSION_NUMBER),) \
			-o $(OUT_SYSTEM)/build.prop
	$(hide) if [ -x $(PRJ_CUSTOM_BUILDPROP) ];then \
			$(PRJ_CUSTOM_BUILDPROP) $(OUT_SYSTEM)/build.prop; \
		fi;
	$(hide) echo ">>> make build.prop done";
	$(hide) echo ">>> Out ==> $(OUT_SYSTEM)/build.prop";

.PHONY: clean-build_prop
clean-build_prop:
	$(hide) rm -rf $(OUT_SYSTEM)/build.prop
	$(hide) rm -rf $(OUT_OBJ_SYSTEM)/baidu.build.prop
