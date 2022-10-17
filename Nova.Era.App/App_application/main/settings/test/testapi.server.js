
module.exports = function (prms, args) {

	let sender = this.createObject('KsSmsSender', {
		url: 'https://sendsms/api/contents',
		login: 'login',
		password: 'password',
		source: 'source'
	});

	let result = sender.sendSms('+380503332233', 'I am the message');
	return result;
};