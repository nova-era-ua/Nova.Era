
const template: Template = {
	commands: {
		addElement,
		removeElement,
		testFetch,
		testInvoke,
		testQueue
	} 
};

export default template;


function addElement(elem) {
	let x = elem.Items.$append({ Name: 'Child element' });
	x.$select(this.Accounts);
}
function removeElement(elem) {
	elem.$remove();
}

async function testFetch() {
	let url = 'https://hola.com/api/auth/';
	let params = {
		body: JSON.stringify({ login: 'user', password: '12345678' }),
		headers: { ContentType: 'application/json' },
		method: 'post'
	};
	try {
		let resp = await fetch(url, params);
		console.dir(resp);
	} catch (err) {
		console.dir(err);
	}
}

async function testInvoke() {
	let ctrl: IController = this.$ctrl;
	try {
		await ctrl.$invoke('testapi', null, null, { catchError: true });
	} catch (err) {
		alert('catched: ' + err.message);
	}
}
async function testQueue() {
	let ctrl: IController = this.$ctrl;
	try {
		await ctrl.$invoke('testqueue', null, null, { catchError: true });
	} catch (err) {
		alert('catched: ' + err);
	}

}