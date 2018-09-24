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
	}
})