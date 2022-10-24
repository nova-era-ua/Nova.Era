

module.exports = function (prms, args) {
	let dm = this.loadModel({
		procedure: 'app.[Integration.Load]',
		parameters: {
			TenantId: prms.TenantId || 1,
			UserId: prms.UserId,
			Id: prms.Id
		}
	});
	let apiKey = dm.Integration.ApiKey;
	return {
		apiKey,
		int: dm.Integration,
		prms,
		args
	};
};
