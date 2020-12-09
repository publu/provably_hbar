pragma solidity 0.5.0;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/token/ERC20/ERC20.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/token/ERC20/ERC20Detailed.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/ownership/Ownable.sol";

import "github.com/provable-things/ethereum-api/provableAPI.sol";
import "github.com/drcfintech/solidity-util/lib/Strings.sol";

contract EasternUnion is ERC20, ERC20Detailed, usingProvable, Ownable{

    using Strings for string;
    
    string ipfsWithdraw = "QmX5saSfADMkPAEtUwc5AHrSSXSGXTAAtVJZVi1vnFyCBk";
    string ipfsDeposit = "QmXVFAxeCYoHzqiWNiqpKRiccbt2ye896KgHVzDPe43bKv";
    string fromAccount = "0.0.5814";
    string privKey = "BI0KW2BUZHvPp6QGqt0P37a6aT6MJsy9FW9P7nRh/hxCK5m8X29SznEeBSn9KA8VSgDs4y2K5G+aO2VUBYEMxSaVCxAEAWMHjD9NVBWFE+YIsZC/fyGWxCV7fPPYv2H1+zFCpcuabb2Trl8lmGcNtfX2u9QxmK7dh8nOdyIOlqrin/ftpGI/DMxpgcgTbDu0ja47XYqTQGfkEMg+th2aIQH4kQ7m23R8L6WrmUyE78/0";
    
    mapping(bytes32 => uint8) query;
    mapping(bytes32 => address) sentBy;
    mapping(bytes32 => uint) pending;
    
    mapping(bytes32 => string) bene;
    mapping(bytes32 => string) queryHash;
    mapping(bytes32 => uint) amt;
    
    mapping(string => bool) done;
    
    uint priceOracle;

    constructor () public payable ERC20Detailed("WrappedHBAR", "WHBAR", 8) {
        // TODO: double-check that the decimals are correct!
    }
    
    event LogEvent(string str);
    
    function _ipfsWithdraw() public view returns (string memory) {
        return ipfsWithdraw;
    }
    
    function _ipfsDeposit() public view returns (string memory) {
        return ipfsDeposit;
    }
    
    function _fromAccount() public view returns (string memory) {
        return fromAccount;
    }
    
    function _privKey() public view returns (string memory) {
        return privKey;
    }
    
    function setWithdraw(string memory str)  public onlyOwner {
        ipfsWithdraw = str;
    }
    
    function setDeposit(string memory str) public onlyOwner {
        ipfsDeposit = str;
    }
    
    function setAccount(string memory str) public onlyOwner {
        fromAccount = str;
    }
    
    function setPriv(string memory str) public onlyOwner {
        privKey = str;
    }

    function checkCost() public view returns (uint) {
        return priceOracle;
    }
    
    function checkTxHash(string memory txH) public view returns (bool){
        return done[txH];
    }
    
    function contains(string memory what, string memory where) private pure returns(bool){
        bytes memory whatBytes = bytes (what);
        bytes memory whereBytes = bytes (where);
    
        bool found = false;
        for (uint i = 0; i < whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        return (found);
    }

    function __callback(bytes32 myid, string memory result) public {
        
       if (msg.sender != provable_cbAddress()) revert();
       
        emit LogEvent(result);
        
        if(query[myid]==0){
            if(parseInt(result)==1 && done[queryHash[myid]] != true){
                done[queryHash[myid]] = true;
                _mint(parseAddr(bene[myid]), amt[myid]);
                amt[myid]=0;
            }else{
                revert();
            }
            query[myid]=2;
        }else if(query[myid]==1){
            // if it fails lets mint it again for them.
            // examples of failure
                // hedera goes down
            // 
            if(parseInt(result)>0){
                // nothing
            }else{
                // this means that it failed and we should unburn the token.
                _mint(sentBy[myid], pending[myid]);
                pending[myid]=0;
            }
            query[myid]=2;
        }else if(query[myid]==2){
            emit LogEvent("Query was already processed.");
        }else{
            emit LogEvent("Something weird happened. Query was not stored prior.");
        }
       emit LogEvent(result);
    }
    
    function withdraw(
        string memory amount, 
        string memory toAccount
        ) public payable {
    // does the transaction contain enough ETH to cover the provable tx?
       
       
       if (priceOracle > msg.value) {
           revert();
       }else{
        
        priceOracle = provable_getPrice("computation");
        // require  amount > 0 hbar
        // trigger computational oraclize call.
        
        // private key encrypted param, is this a safe choice? Yes (by oraclize)
        // account id unencrypted param
        uint withdrawAmount = parseInt(amount);
        require(withdrawAmount>0);
        _burn(_msgSender(), withdrawAmount); // we'll try to burn it.  

        // then we call the decentralized hedera account () 

        bytes32 a = provable_query("computation", 
                    [ipfsWithdraw,
                    privKey,
                    fromAccount,
                    toAccount,
                    amount
                    ]);
        sentBy[a] = msg.sender;
        pending[a] = withdrawAmount;
        query[a] = 1;
       }
    }
    
    function verifyDeposit(
            string memory txHash, 
            string memory beneficiary, 
            string memory amount
    ) public payable {
    // does the transaction contain enough ETH to cover the provable tx?

       require(done[txHash] != true);
       if (priceOracle > msg.value) {
           revert();
       } else {
            priceOracle = provable_getPrice("computation");

            bytes32 q = provable_query("computation", 
            [ipfsDeposit,
            txHash,
            fromAccount,
            amount,
            beneficiary]
            );

            queryHash[q] = txHash;
            bene[q] = beneficiary;
            amt[q] = parseInt(amount);
            
            query[q] = 0; // Step 0: Kabuto request.
       }
    }
}
