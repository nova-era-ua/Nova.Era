// download banks from NBU site

module.exports = function (prms, args) {
	let resp = this.fetch('https://bank.gov.ua/NBU_BankInfo/get_data_branch_glbank?json=1');
	if (resp.ok) {
		let list = JSON.parse(resp.text());
		let dm = this.saveModel({
			procedure: 'cat.[Bank.Upload.Update]',
			data: {
				Banks: list,
			},
			parameters: {
				UserId: prms.UserId
			}
		});
		return {
			success: true,
			Loaded: dm.Result.Loaded
		};
	}
	return {
		success: false,
		error: resp.statusText
	}
};