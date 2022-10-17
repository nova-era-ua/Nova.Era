define(["require", "exports"], function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    const module = {
        kind2Text
    };
    exports.default = module;
    function kind2Text(kind) {
        switch (kind) {
            case 'I': return 'Новий';
            case 'P': return 'В обробці';
            case 'S': return 'Завершено';
            case 'C': return 'Скасовано';
        }
        return kind;
    }
});
