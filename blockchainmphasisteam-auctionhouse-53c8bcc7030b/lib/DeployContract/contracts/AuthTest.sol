pragma solidity ^0.4.14;
import './Verifier.sol';
contract AuthTest is Verifier {



    event VerifySuccess(bool data);
    event testEvent(uint256 test);
    bool public success = false;
    uint256 public test = 101;
function setTestFunc() public {
    test=10;
    emit testEvent(test);
}

function getTestFunc() constant public returns(uint256){
    return test;
}

    function verifyFifteen(
        uint[2] a,
        uint[2] a_p,
        uint[2][2] b,
        uint[2] b_p,
        uint[2] c,
        uint[2] c_p,
        uint[2] h,
        uint[2] k,
        uint[5] input) public {
        // Verifiy the proof
	emit VerifySuccess(success);
        success = verifyTx(a, a_p, b, b_p, c, c_p, h, k, input);
        if (success) {
            // Proof verified
		emit VerifySuccess(success);
        } else {
            // Sorry, bad proof!
		emit VerifySuccess(success);
        }

	//return(success);
    }

	function getSuccess()constant public returns(bool){
		return (success);
	}
}