async function loadItems(url) {
    var items = [];
    var fetchFrom = url;
    while (fetchFrom != null) {
        var response = await fetch(fetchFrom) 
        var payload = await response.json();            
        var result = payload.value;
        result.forEach(item => items.push(item));    
        if (payload.nextLink) {
            //console.log(`loading next item set: ${payload.nextLink}`)
            fetchFrom = payload.nextLink;
        } else {
            fetchFrom = null
        }
    }
    return items;
}

var items = await loadItems('https://localhost:5001/api/todo?$first=1000')

console.log(items.length);