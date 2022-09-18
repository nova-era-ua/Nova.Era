
const template: Template = {
	events: {
		"Model.load": modelLoad
	}
}

export default template;

async function modelLoad(this: any) {
	console.dir('start');
	let arr = [
		'/_page/widgets/widget3/index/1004?Row=1&Col=1',
		'/_page/widgets/widget2/index/1004?Row=1&Col=1',
		'/_page/widgets/widget1/index/1004?Row=1&Col=1',
		'/_page/widgets/widget4/index/1004?Row=1&Col=1',
		'/_page/widgets/widget3/index/1004?Row=1&Col=1',
		'/_page/widgets/widget1/index/1004?Row=1&Col=1',
		'/_page/widgets/widget2/index/1004?Row=1&Col=1',
	];

	let h = {
		'X-Requested-With': 'XMLHttpRequest',
		'Accept': 'application/json, text/html'
	};

	for (let i = 0; i < arr.length; i++) {
		let url = arr[i];
		await fetch(url, {
			method: 'GET',
			mode: 'same-origin',
			headers: h
		});
	}

	/*

	fetch('/_batch/index/0', {
		method: 'POST',
		mode: 'same-origin',
		headers: {
			'X-Requested-With': 'XMLHttpRequest',
			'Accept': 'application/json, text/html'
		},
		body: JSON.stringify(arr)
	}).then(res => {
		console.dir(res);
	});
	*/
}