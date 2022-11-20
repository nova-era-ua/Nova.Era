
module.exports = function (prms, args) {

    let url = 'https://hola.com/api/auth/';
    let params = {
        body: { login: 'user', password: '12345678' },
        headers: { ContentType: 'application/json' },
        method: 'post'
    };

    try {
        let resp = this.fetch(url, prms);
    }
    catch (err)
    {
        return {
            success: false,
            err: err.message
        };
    }
};