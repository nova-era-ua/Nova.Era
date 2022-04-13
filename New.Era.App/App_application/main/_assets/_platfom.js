
app.modules["std:tmlutils"] = {
	mergeTemplate
};

function mergeTemplate(src, tml) {
	return Object.assign(src, {
		properties: Object.assign(src.properties, tml.properties),
		validators: Object.assign(src.validators, tml.validators),
		events: Object.assign(src.events, tml.events),
		defaults: Object.assign(src.defaults, tml.defaults),
		commands: Object.assign(src.commands, tml.commands)
	});
}
