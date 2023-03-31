/*@localize*/
/**TODO
 * 3. GrandTotal
 * 4. Code - основное рабочее время. Все остальные - включая (!)
 * 6. Open/Close dropDown
 * 7. All double borders
 * 9. Display totalDays workdays
 * 10. Clear cell command
 */

(() =>
{
	const timeBoardTemplate = `
	<div class="time-board">
		<table>
			<thead>
				<tr>
					<th class="bt-2 bl-2" rowspan=3>№</th>
					<th class="bt-2" colspan=2>@[Employee]</th>
					<th class="bt-2" colspan=2>@[Schedule]</th>
					<th class="bt-2" :colspan="calLength">Робочий час</th>
					<th class="bt-2" :colspan="presences.length + 1">Відпрацьовано</th>
					<th class="bt-2" colspan=6>Неявки (дні/години)</th>
				</tr>
				<tr>
					<th colspan=2>П.І.Б</th>
					<th rowspan=2>Дні</th>
					<th rowspan=2>Години</th>
					<th v-for="d in topDays" v-text="d" class="center"></th>
					<th rowspan=2>Дні</th>
					<th :colspan="presences.length">Години</th>
					<th rowspan=2 class=center v-for="a in absences" v-text="a.Code" :title="a.Name"></th>
				</tr>
				<tr>
					<th>Таб.№</th>
					<th>Посада</th>
					<th class="center" v-for="d in bottomDays" v-text="d"></th>
					<th class="center" v-for="a in presences" v-text="a.Code" :title="a.Name"></th>
				</tr>
			</thead>
			<tbody>
				<template v-for="(row, rx) in rows">
					<tr>
						<td rowspan=2 class="cb bl-2" v-text="row.RowNo"></td>
						<td colspan=2>Співробітник #1</td>
						<td colspan=2>Основний</td>
						<td class="center code-ed" v-for="td in topDays" :class="cellClass(row, td)" 
							v-text="cellText(row, td)" @mousedown.stop.prevent="click($event, row, td)"></td>
						<td rowspan=2>days</td>
						<td rowspan=2 class="text-right dis" v-for="a in presences" v-text="totalHours(row, a.Id)"></td>
						<td v-for="a in absences" class="text-right" :class="'code-' + a.Color" v-text="totalDays(row, a.Id)"></td>
					</tr>
					<tr>
						<td class=cb>002</td>
						<td class=cb>Посада</td>
						<td class="cb text-right">8</td>
						<td class="cb text-right">156</td>
						<td class="cb center code-ed" v-for="bd in bottomDays" :class="cellClass(row, bd)" 
							v-text="cellText(row, bd)" @mousedown.stop.prevent="click($event, row, bd)"></td>
						<td v-for="a in absences" class="text-right cb" :class="'code-' + a.Color" v-text="totalHours(row, a.Id)"></td>
					</tr>
				</template>
			</tbody>
			<tfoot>
				<tr>
					<th :colspan="calLength + 5" rowspan=2>Всього</th>
					<th>12</th>
					<th></th>
				</tr>
				<tr>
					<th>11</th>
				</tr>
			</tfoot>
		</table>
		<ul class="menu timeboard-select" ref=menu>
			<li>
				<div class="wd">
					<div v-for="c in presences" class="no-wrap">
						<label v-text=c.Code :title="c.Name"></label>
						<input :value="workHours(c.Id)" @input="setWorkHours($event, c.Id)">
					</div>
				</div>
			</li>
			<li class="sel" v-for="c in absences" @click.stop.prevent="setDay(c.Id)">
				<span class="code" :class="'code-' + c.Color" v-text=c.Code></span> <span v-text="c.Name"></span>
			</li>
			<li class="sel clear">
				<span>Очистити</span>
			</li>
		</ul>
	</div>
	`;

	const range = (min, max) =>
		Array.apply(null, Array(max - min + 1)).map((i, j) => '' + (j + min));

	const createCodeMap = (codes) => 
		Object.assign({}, ...codes.map(x => ({ [x.Id]: x })));

	const weekdayClass = (date, day) => {
		let x = new Date(date.getFullYear(), date.getMonth(), day, 0, 0, 0, 0).getDay();
		return x === 0 ? 'wkday-sun' : x === 6 ? 'wkday-sat' : '';
	};


	Vue.component('a2-timeboard', {
		template: timeBoardTemplate,
		props: {
			rows: Array,
			period: Date,
			codes: Array
		},
		data() {
			return {
				codeMap: createCodeMap(this.codes),
				currentRow: Object,
				currentDay: ''
			};
		},
		computed: {
			dayOfMonth() {
				return new Date(this.period.getFullYear(), this.period.getMonth() + 1, 0).getDate();
			},
			calLength() {
				return this.dayOfMonth > 30 ? 16 : 15;
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
			},
			absences() {
				return this.codes.filter(x => x.Type == 2);
			},
			presences() {
				return this.codes.filter(x => x.Type < 2);
			}
		},
		methods: {
			cellText(row, day) {
				let dd = row.Days[day];
				if (!dd) return '';
				if (!dd.DayData.length)
					return;
				if (dd.DayData.length == 1) {
					let x = this.codeMap[dd.DayData[0].Code];
					if (x.Type === 2)
						return x.Code;
				}
				return dd.DayData
					.filter(x => x.Code && this.codeMap[x.Code].Type < 2)
					.map(x => `${this.codeMap[x.Code].Code}${x.Duration / 60}`)
					.join('\n');
			},
			codeValue(row, day) {
				let dd = row.Days[day];
				if (!dd) return null;
				if (dd.DayData.length == 1)
					return this.codeMap[dd.DayData[0].Code];
				return null;
			},
			cellClass(row, day) {
				let cls = [weekdayClass(this.period, day)];
				let dd = row.Days[day];
				if (row === this.currentRow && day === this.currentDay)
					cls.push('active');
				if (dd) {
					if (dd.DayData.length == 1) {
						let codeVal = this.codeMap[dd.DayData[0].Code];
						if (codeVal && codeVal.Color)
							cls.push(`code-${codeVal.Color}`);
					}
				} else
					cls.push('no-data');
				return cls.join(' ');
			},
			click(event, row, day) {
				let rd = row.Days[day];
				if (!rd) return;
				this.currentRow = row;
				this.currentDay = day;
				let menu = this.$refs.menu;
				let td = event.srcElement;
				menu.style.top = (td.offsetTop + td.offsetHeight + 1) + 'px';
				menu.style.left = td.offsetLeft + 'px';
				var ae = document.activeElement;
				if (ae && ae.blur) ae.blur();
			},
			totalDays(row, code) {
				let x = range(1, 31).reduce(
					(p, c) => p + row.Days[c].DayData.filter(x => x.Code === code).length,
				0);
				return x ? x : '';
			},
			totalHours(row, code) {
				let x = range(1, 31).reduce(
					(p, c) => p + row.Days[c].DayData.filter(dd => dd.Code === code)
						.reduce((pd, cd) => pd + cd.Duration, 0),
				0);
				return x ? x / 60 : '';
			},
			setDay(code) {
				if (!this.currentRow || !this.currentDay) return;
				let rd = this.currentRow.Days[this.currentDay];
				if (!rd) return;
				rd.DayData.$empty();
				let dd = rd.DayData.$append({ Code: code, Duration:480, Day: this.currentDay });
			},
			workHours(code) {
				if (!this.currentRow || !this.currentDay) return '';
				let rd = this.currentRow.Days[this.currentDay];
				if (!rd) return '';
				let dd = rd.DayData.find(x => x.Code === code);
				return dd ? dd.Duration / 60 : '';
			},
			setWorkHours($event, code) {
				if (!this.currentRow || !this.currentDay) return;
				let rd = this.currentRow.Days[this.currentDay];
				if (!rd) return;
				let value = + $event.srcElement.value;
				let dd = rd.DayData.find(x => x.Code === code);
				// todo: remove all from absences
				if (!dd)
					dd = rd.DayData.$append({ Code: code, Day: this.currentDay });
				rd.DayData.forEach(d => {
					let c = this.codeMap[d.Code];
					if (c.Type === 2) d.$remove();
				});
				if (value)
					dd.Duration = value * 60;
				else
					dd.$remove();
			}

		}
	});
})();