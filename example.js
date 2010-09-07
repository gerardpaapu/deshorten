/**
 * This is just an example of how you might use the service
 * it uses MooTools 1.2.4 and some elements of MooTools More
 */
function deshorten(links) {
    var links = $$(links),
        urls  = links.get('href'),
        table = $H(links.associate(urls));

    new Request.JSONP({
        url: 'http://gerardpaapu.com/deshorten',
        data: {'short': urls.join(',')},
        onComplete: function (json){
            $H(json).each(function(longUrl, shortUrl){
                var oldLink = table.get(shortUrl),
                    newLink = new Element('a', {
                        'href': longUrl,
                        'text': longUrl
                    });

                if (oldLink) newLink.replaces(oldLink);
            });
        }
    }).send();

    
}

window.addEvent('domready', function () {
    deshorten('a[href^=http://bit.ly]');
});
