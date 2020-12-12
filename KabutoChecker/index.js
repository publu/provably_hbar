const fetch = require('node-fetch');

(async () => {
    let memo = process.argv[5];
    let amount = process.argv[4];
    let toAccount = process.argv[3];
    let txHash = process.argv[2];

    const response = await fetch('https://api.testnet.kabuto.sh/v1/transaction?q={"hash":"'+txHash+'"}');
    const body = JSON.parse(await response.text());
    /*
        Here we need to check for a specific amount and account id that should be getting 
    */
    let transaction = body.transactions[0];
    
    var r = 0;
    for(var t in transaction.transfers){
        if(transaction.transfers[t]["account"] == toAccount &&
            transaction.transfers[t]["amount"] == amount){
            r=1;
        }
    }
    if(transaction.status!="SUCCESS"){
        r==0;
    }

    if(transaction.memo!=memo){
        r=0;
    }
    console.log(r);
    process.exit(0);
})();
