pragma solidity 0.4.25;


import 'libraries/ITyped.sol';
import 'libraries/IOwnable.sol';
import 'libraries/token/ERC20.sol';
import 'trading/IShareToken.sol';
import 'reporting/IUniverse.sol';
import 'reporting/IReportingParticipant.sol';


contract IMarket is ITyped, IOwnable {
    enum MarketType {
        YES_NO,
        CATEGORICAL,
        SCALAR
    }

    function initialize(IUniverse _universe, uint256 _endTime, uint256 _feePerEthInAttoeth, ERC20 _denominationToken, address _designatedReporterAddress, address _creator, uint256 _numOutcomes, uint256 _numTicks) public returns (bool _success);
    function derivePayoutDistributionHash(uint256[] _payoutNumerators, bool _invalid) public view returns (bytes32);
    function getUniverse() public view returns (IUniverse);
    function getNumberOfOutcomes() public view returns (uint256);
    function getNumTicks() public view returns (uint256);
    function getDenominationToken() public view returns (ERC20);
    function getShareToken(uint256 _outcome)  public view returns (IShareToken);
    function getEndTime() public view returns (uint256);
    function getMarketCreatorMailbox() public view returns (address);
    function getWinningPayoutDistributionHash() public view returns (bytes32);
    function getWinningPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getFinalizationTime() public view returns (uint256);
    function getInitialReporterAddress() public view returns (address);
    function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256);
    function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool);
    function isContainerForReportingParticipant(IReportingParticipant _reportingParticipant) public view returns (bool);
    function isInvalid() public view returns (bool);
    function finalize() public returns (bool);
    function isFinalized() public view returns (bool);
    function assertBalances() public view returns (bool);
}
