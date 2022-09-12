
const template: Template = {
	commands: {
		cmd1
	}
}

export default template;

async function cmd1() {
	await this.$ctrl.$invoke('cmd1');
}