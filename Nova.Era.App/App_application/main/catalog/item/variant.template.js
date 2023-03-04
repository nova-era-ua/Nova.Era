define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const template = {
        properties: {
            'TRoot.$Options2': options2,
            'TRoot.$Options3': options3,
            'TRoot.$Opt2Visible'() { return !!this.Item.Option1.Id; },
            'TRoot.$Opt3Visible'() { return !!this.Item.Option1.Id && !!this.Item.Option2.Id; },
            'TItem.Variants': variants
        },
        events: {
            'Model.load': modelLoad
        },
        validators: {},
        commands: {
            setupVariants
        }
    };
    exports.default = template;
    function modelLoad() {
        if (this.Options.length > 0) {
            this.Item.Option1 = this.Options[0];
            this.$defer(() => this.$setDirty(true));
        }
    }
    function options2() {
        let id1 = this.Item.Option1.Id;
        if (!id1)
            return [];
        return this.Options.filter(x => x.Id !== id1);
    }
    function options3() {
        let id1 = this.Item.Option1.Id;
        let id2 = this.Item.Option2.Id;
        if (!id1 || !id2)
            return [];
        return this.Options.filter(x => x.Id !== id1 && x.Id !== id2);
    }
    function variants() {
        let arr = [];
        this.Option1.Values.filter(o1 => o1.Checked).forEach(v1 => {
            if (this.Option2.Id)
                this.Option2.Values.filter(o2 => o2.Checked).forEach(v2 => {
                    if (this.Option3.Id)
                        this.Option3.Values.filter(o3 => o3.Checked).forEach(v3 => {
                            arr.push({
                                Id1: v1.Id, Name1: v1.Name,
                                Id2: v2.Id, Name2: v2.Name,
                                Id3: v3.Id, Name3: v3.Name,
                                Name: `${v1.Name}, ${v2.Name}, ${v3.Name}`,
                                Article: '', Barcode: ''
                            });
                        });
                    else
                        arr.push({
                            Id1: v1.Id, Name1: v1.Name,
                            Id2: v2.Id, Name2: v2.Name,
                            Id3: 0, Name3: null,
                            Name: `${v1.Name}, ${v2.Name}`,
                            Article: '', Barcode: ''
                        });
                });
            else
                arr.push({
                    Id1: v1.Id, Name1: v1.Name,
                    Id2: 0, Name2: null,
                    Id3: 0, Name3: null,
                    Name: v1.Name,
                    Article: '', Barcode: ''
                });
        });
        return arr;
    }
    async function setupVariants() {
        const ctrl = this.$ctrl;
        await ctrl.$showDialog('/catalog/itemoption/setup');
        ctrl.$requery();
    }
});
