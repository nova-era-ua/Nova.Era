define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const utils = require("std:utils");
    const dateUtils = utils.date;
    const currencyUtils = utils.currency;
    function docToBaseDoc(doc) {
        return {
            Id: doc.Id,
            Date: doc.Date,
            Sum: doc.Sum,
            OpName: doc.Operation.Name,
            Form: doc.Operation.Form,
            Done: doc.Done
        };
    }
    const template = {
        properties: {
            'TDocBase.$Name': docBaseName,
            'TDocBase.$Icon'() { return this.Done ? 'success-green' : 'warning-yellow'; },
            'TDocument.$CompanyAgentArg'() { return { Company: this.Company.Id, Agent: this.Agent.Id }; }
        },
        defaults: {
            'Document.Date': dateUtils.today(),
            'Document.Operation'() { return this.Operations.find(o => o.Id === this.Params.Operation); },
            'Document.Company'() { return this.Default.Company; },
            'Document.RespCenter'() { return this.Default.RespCenter; }
        },
        validators: {
            'Document.Company': '@[Error.Required]',
            'Document.Agent': '@[Error.Required]',
        },
        events: {
            'Document.Contract.change': contractChange,
            'Document.Agent.change': agentChange,
            'Document.Company.change': companyChange,
            'app.document.saved': handleLinkSaved,
            'app.document.apply': handleLinkApply
        },
        commands: {
            apply: {
                exec: apply,
                confirm: '@[Confirm.Apply]'
            },
            unApply: {
                exec: unApply,
                confirm: '@[Confirm.UnApply]'
            },
            createOnBase,
            openLinked
        },
        delegates: {
            canClose
        }
    };
    exports.default = template;
    function docBaseName() {
        return `${this.OpName}\nвід ${dateUtils.formatDate(this.Date)} на суму ${currencyUtils.format(this.Sum)}`;
    }
    function contractChange(doc, contract) {
        if (contract.Agent.Id)
            doc.Agent = contract.Agent;
        if (contract.Company.Id)
            doc.Company = contract.Company;
    }
    function agentChange(doc, agent) {
        if (doc.Contract.Agent.Id !== agent.Id)
            doc.Contract.$empty();
    }
    function companyChange(doc, company) {
        if (doc.Contract.Company.Id !== company.Id)
            doc.Contract.$empty();
    }
    function handleLinkSaved(elem) {
        let doc = elem.Document;
        let found = this.Document.LinkedDocs.find(e => e.Id === doc.Id);
        if (found) {
            found.Sum = doc.Sum;
            found.Date = doc.Date;
            found.OpName = doc.Operation.Name;
        }
        else
            this.Document.LinkedDocs.$append(docToBaseDoc(doc));
    }
    function handleLinkApply(elem) {
        let found = this.Document.LinkedDocs.find(e => e.Id === elem.Id);
        if (found)
            found.Done = elem.Done;
    }
    async function apply() {
        const ctrl = this.$ctrl;
        await ctrl.$invoke('apply', { Id: this.Document.Id });
        ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: true });
        ctrl.$requery();
    }
    async function unApply() {
        const ctrl = this.$ctrl;
        await ctrl.$invoke('unApply', { Id: this.Document.Id });
        ctrl.$emitCaller('app.document.apply', { Id: this.Document.Id, Done: false });
        ctrl.$requery();
    }
    async function createOnBase(link) {
        const ctrl = this.$ctrl;
        await ctrl.$save();
        let res = await ctrl.$invoke('createonbase', { Document: this.Document.Id, LinkId: link.Id }, '/document/commands');
        let url = `/document/${res.Document.Form}/edit`;
        await ctrl.$showDialog(url, { Id: res.Document.Id });
    }
    async function openLinked(doc) {
        const ctrl = this.$ctrl;
        let url = `/document/${doc.Form}/edit`;
        await ctrl.$showDialog(url, { Id: doc.Id });
    }
    function canClose() {
        return this.$ctrl.$saveModified('@[Confirm.Document.SaveModified]');
    }
});
