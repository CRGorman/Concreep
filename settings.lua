data:extend({
    {
        type = "int-setting",
        name = "concreep range",
        setting_type = "runtime-global",
        default_value = 100,
        minimum_value = 0,
        maximum_value = 100,
        order = "01"
    },
    {
        type = "int-setting",
        name = "concreep construction factor",
        setting_type = "runtime-global",
        default_value = 10,
        minimum_value = 1,
        maximum_value = 20,
        order = "02"
    },
	{
		type = "bool-setting",
		name = "ignore placed tiles",
		setting_type = "runtime-global",
		default_value = true,
		order = "03"
    },
    {
        type = "string-setting",
        name = "alternate pavement",
        setting_type = "runtime-global",
        default_value = "refined-concrete",
        order = "04"
    },
    {
        type = "bool-setting",
        name = "debug mode",
        setting_type = "runtime-global",
        default_value = false,
        order = "05"
    },
    {
        type = "int-setting",
        name = "tick count",
        setting_type = "runtime-global",
        default_value = 1800,
        minimum_value = 600,
        maximum_value = 18000,
        order = "06"
    }
})