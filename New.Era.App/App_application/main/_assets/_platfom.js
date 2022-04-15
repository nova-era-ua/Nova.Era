
app.modules["std:tmlutils"] = {
	mergeTemplate
};

function mergeTemplate(src, tml) {
	function assign(s, t) {
		return Object.assign({}, s || {}, t || {});
	}
	return assign(src, {
		properties: assign(src.properties, tml.properties),
		validators: assign(src.validators, tml.validators),
		events: assign(src.events, tml.events),
		defaults: assign(src.defaults, tml.defaults),
		commands: assign(src.commands, tml.commands)
	});
}
