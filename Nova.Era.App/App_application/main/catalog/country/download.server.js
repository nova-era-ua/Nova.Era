module.exports = function (prms, args) {

	let resp = this.fetch('https://bank.gov.ua/NBUStatService/v1/statdirectory/stat/dim/kl_K040');
	if (resp.ok) {
		let list = JSON.parse(resp.text());
		list = list
			.filter(x => x.K040 !== '#')
			.map(x => { return { Id: x.K040, Alpha2: x.A2, Alpha3: x.KOD_LIT, Name: x.TXT }; });
		return {
			success: true,
			List: list
		};
	}
	return {
		success: false,
		error: resp.statusText
	}
};