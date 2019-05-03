pragma solidity 0.4.25;

import 'libraries/Initializable.sol';
import 'libraries/DelegationTarget.sol';
import 'reporting/IInitialReporter.sol';
import 'reporting/IMarket.sol';
import 'reporting/BaseReportingParticipant.sol';
import 'libraries/Ownable.sol';


contract InitialReporter is DelegationTarget, Ownable, BaseReportingParticipant, Initializable, IInitialReporter {
    address private designatedReporter;
    address private actualReporter;
    uint256 private reportTimestamp;

    function initialize(IMarket _market, address _designatedReporter) public onlyInGoodTimes beforeInitialized returns (bool) {
        endInitialization();
        market = _market;
        designatedReporter = _designatedReporter;
        return true;
    }

    function report(address _reporter, bytes32 _payoutDistributionHash, uint256[] _payoutNumerators, bool _invalid) public onlyInGoodTimes returns (bool) {
        require(IMarket(msg.sender) == market);
        actualReporter = _reporter;
        owner = _reporter;
        payoutDistributionHash = _payoutDistributionHash;
        reportTimestamp = controller.getTimestamp();
        invalid = _invalid;
        payoutNumerators = _payoutNumerators;
        return true;
    }

    function resetReportTimestamp() public onlyInGoodTimes returns (bool) {
        require(IMarket(msg.sender) == market);
        if (reportTimestamp == 0) {
            return;
        }
        reportTimestamp = controller.getTimestamp();
        return true;
    }

    function getDesignatedReporter() public view returns (address) {
        return designatedReporter;
    }

    function getReportTimestamp() public view returns (uint256) {
        return reportTimestamp;
    }

    function designatedReporterShowed() public view returns (bool) {
        return actualReporter == designatedReporter;
    }

    function onTransferOwnership(address _owner, address _newOwner) internal returns (bool) {
        controller.getAugur().logInitialReporterTransferred(market.getUniverse(), market, _owner, _newOwner);
        return true;
    }
}
