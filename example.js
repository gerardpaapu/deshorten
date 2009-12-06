/**
 * This is just an example of how you might use the service
 * it uses MooTools 1.2.4 and some elements of MooTools More
 */
function deshorten(links) {
    var urls  = links.map(getHref),
        table = $H(links.associate(urls)),
        req   = new Request.JSONP({
            url: 'http://thecyberplains.com:8000/',
            data: {'short': urls.join(',')},
            onComplete: callBack
        });

    req.send();
    
    function callBack (json) {
        $H(json).each(
            function(longUrl, shortUrl){
                var oldLink = table.get(shortUrl),
                    newLink = new Element('a', {
                        'href': longUrl,
                        'text': longUrl
                    });

                newLink.replaces(oldLink);
            });
    }

    function getHref(o) {
        return o.get('href');
    }
}

window.addEvent('domready', function () {
    deshorten($$('a[href^=http://]'));
});