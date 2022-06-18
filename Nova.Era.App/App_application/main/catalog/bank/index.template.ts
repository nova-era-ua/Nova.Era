// bank.index.template

const template: Template = {
	commands: {
		download
	}
};

export default template;


async function download() {
	const ctrl: IController = this.$ctrl;
	let result = await ctrl.$invoke('downloadBanks');
	if (result.success) {
		ctrl.$alert({ msg: '@[BanksDownloaded]: ' + result.Loaded, style: MessageStyle.info });
		await ctrl.$reload();
	} else {
		alert(result.error);
	}
}