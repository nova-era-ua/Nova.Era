
const module = {
	kind2Text
};

export default module;


function kind2Text(kind) {
	switch (kind) {
		case 'I': return 'Новий'
		case 'P': return 'В обробці'
		case 'S': return 'Завершено'
		case 'C': return 'Скасовано'
	}
	return kind;
}