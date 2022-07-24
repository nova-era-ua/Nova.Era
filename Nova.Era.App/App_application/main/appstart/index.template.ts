// welcome!

const template: Template = {
	commands: {
		start
	}
}

export default template;

function start() {
	alert('start here');
	window.location.assign("/");
}