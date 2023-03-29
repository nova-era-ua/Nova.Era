/**TODO
 * 2. Выходные подсветить
 * 3. Всего дней/часов
 */

(() =>
{
	const timeTableTemplate = `
	<div class="time-table">
		<div v-text="period"></div>
		<table>
			<thead>
				<tr>
					<th rowspan=2>№</th>
					<th></th>
					<th v-for="d in topDays" v-text="d"></th>
				</tr>
				<tr>
					<th></th>
					<th v-for="d in bottomDays" v-text="d"></th>
				</tr>
			</thead>
			<tbody>
				<template v-for="(row, rx) in rows">
					<tr>
						<td rowspan=2 class=cb></td>
						<td>Employee name</td>
						<td v-for="td in topDays" :class="cellClass(row, td)" v-text="cellText(row, td)"></td>
					</tr>
					<tr>
						<td class=cb></td>
						<td class=cb v-for="bd in bottomDays" :class="cellClass(row, bd)" v-text="cellText(row, bd)"></td>
					</tr>
				</template>
			</tbody>
		</table>
	</div>
	`;

	const range = (min, max) =>
		Array.apply(null, Array(max - min + 1)).map((i, j) => '' + (j + min));
	const createCodeMap = (codes) => 
		Object.assign({}, ...codes.map(x => ({ [x.Id]: x })));
	const isWeekend = (date, day) => {
		let x = new Date(date.getFullYear(), date.getMonth(), day, 0, 0, 0, 0).getDay();
		return x == 0 || x == 6;
	}


	Vue.component('a2-timetable', {
		template: timeTableTemplate,
		props: {
			rows: Array,
			period: Date,
			codes: Array
		},
		data() {
			return {
				codeMap: createCodeMap(this.codes)
			};
		},
		computed: {
			dayOfMonth() {
				return new Date(this.period.getFullYear(), this.period.getMonth() + 1, 0).getDate();
			},
			topDays() {
				let r = range(1, 15);
				if (this.dayOfMonth > 30)
					r.push('');
				return r;
			},
			bottomDays() {
				let dm = this.dayOfMonth;
				let r = range(16, dm);
				while (r.length < 15)
					r.push('');
				return r;
			}
		},
		methods: {
			cellText(row, day) {
				let dd = row.RowData[day];
				if (!dd) return '';
				return dd.DayData
					.filter(x => x.Code && this.codeMap[x.Code].HasTime)
					.map(x => `${this.codeMap[x.Code].Code}${x.Duration / 60}`)
					.join('\n');
			},
			cellClass(row, day) {
				if (isWeekend(this.period, day))
					return 'weekend';   
				let dd = row.RowData[day];
				if (!dd) return undefined;
				return 'blue';
			}
		}
	});
})();