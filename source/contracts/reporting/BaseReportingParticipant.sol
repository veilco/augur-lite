pragma solidity 0.4.25;

import 'reporting/IReportingParticipant.sol';
import 'reporting/IMarket.sol';
import 'Controlled.sol';


contract BaseReportingParticipant is Controlled, IReportingParticipant {
    bool internal invalid;
    IMarket internal market;
    bytes32 internal payoutDistributionHash;
    uint256[] internal payoutNumerators;

    function isInvalid() public view returns (bool) {
        return invalid;
    }

    function getPayoutDistributionHash() public view returns (bytes32) {
        return payoutDistributionHash;
    }

    function getMarket() public view returns (IMarket) {
        return market;
    }

    function getPayoutNumerator(uint256 _outcome) public view returns (uint256) {
        return payoutNumerators[_outcome];
    }
}
