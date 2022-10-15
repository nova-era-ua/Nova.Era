
const module = {
	kind2Text
};

export default module;


function kind2Text(kind) {
	switch (kind) {
		case 'I': return 'Новий'
		case 'P': return 'В обробці'
		case 'S': return 'Успіх'
		case 'F': return 'Невдача'
	}
	return kind;
}