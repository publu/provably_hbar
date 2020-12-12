var { Client, TransferTransaction, Hbar } = require("@hashgraph/sdk");

const operatorPrivateKey = process.argv[2];//"302e020100300506032b6570042204209774270bde2b5d40ce4f588fd72eeddd4e972193b82ffce3b2ca27558d0d2c83";//process.argv[2];
const operatorAccount = process.argv[3];//"0.0.5814";//input[2];
const operatorMemo = "sending TEE tx";
const operatorAmount = process.argv[5];//"10000000";//input[0];
const operatorRecipient = process.argv[4];//"0.0.3000";//input[1];

const client = Client.forTestnet();
client.setOperator(operatorAccount, operatorPrivateKey);

async function main(){
    const receipt = await (await new TransferTransaction()
        .addHbarTransfer(operatorRecipient, new Hbar(operatorAmount/100000000))
        .addHbarTransfer(operatorAccount, new Hbar(operatorAmount/100000000).negated())
        .setTransactionMemo(operatorMemo)
        .execute(client))
        .getReceipt(client);
    if(receipt.status._code==22){
        console.log(operatorAmount/100000000);
    }else{
        console.log("0");
    }
    process.exit(0);
}
main();
