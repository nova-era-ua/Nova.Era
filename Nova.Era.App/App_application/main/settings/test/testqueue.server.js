
module.exports = function (prms, args) {

	let params = {
		procedure: 'dbo.[BackgroundSql]',
		parameters: {
			UserId: 99,
			Message: 'ExecuteMessage'
		}
	};
	let email = {
		to: 'user@user.com',
		subject: 'message subject',
		body: 'message body'
	};
	//return this.queueTask('ExecuteSql', params, new Date());
	return this.queueTask('SendMail', email, new Date());
};