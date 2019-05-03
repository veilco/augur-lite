pragma solidity 0.4.25;

import 'reporting/IMarket.sol';
import 'libraries/DelegationTarget.sol';
import 'libraries/ITyped.sol';
import 'libraries/Initializable.sol';
import 'libraries/Ownable.sol';
import 'reporting/IUniverse.sol';
import 'reporting/IReportingParticipant.sol';
import 'libraries/token/ERC20.sol';
import 'trading/IShareToken.sol';
import 'factories/ShareTokenFactory.sol';
import 'factories/InitialReporterFactory.sol';
import 'libraries/math/SafeMathUint256.sol';
import 'libraries/math/SafeMathInt256.sol';
import 'reporting/IInitialReporter.sol';


contract Market is DelegationTarget, ITyped, Initializable, Ownable, IMarket {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    // Constants
    uint256 private constant MAX_FEE_PER_ETH_IN_ATTOETH = 1 ether / 2;
    uint256 private constant APPROVAL_AMOUNT = 2 ** 256 - 1;
    address private constant NULL_ADDRESS = address(0);
    uint256 private constant MIN_OUTCOMES = 2;
    uint256 private constant MAX_OUTCOMES = 8;

    // Contract Refs
    IUniverse private universe;
    ERC20 private denominationToken;

    // Attributes
    uint256 private numTicks;
    uint256 private feeDivisor;
    uint256 private endTime;
    uint256 private numOutcomes;
    bytes32 private winningPayoutDistributionHash;
    uint256 private finalizationTime;
    address private marketCreatorMailbox;

    // Collections
    IReportingParticipant[] public participants;
    IShareToken[] private shareTokens;

    function initialize(IUniverse _universe, uint256 _endTime, uint256 _feePerEthInAttoeth, ERC20 _denominationToken, address _designatedReporterAddress, address _creator, uint256 _numOutcomes, uint256 _numTicks) public onlyInGoodTimes beforeInitialized returns (bool _success) {
        endInitialization();
        require(MIN_OUTCOMES <= _numOutcomes && _numOutcomes <= MAX_OUTCOMES);
        require(_numTicks > 0);
        require(_designatedReporterAddress != NULL_ADDRESS);
        require((_numTicks >= _numOutcomes));
        require(_feePerEthInAttoeth <= MAX_FEE_PER_ETH_IN_ATTOETH);
        require(_creator != NULL_ADDRESS);
        require(controller.getTimestamp() < _endTime);
        // require(address(_denominationToken) == controller.lookup("DenominationToken")); // Mert
        universe = _universe;
        owner = _creator;
        endTime = _endTime;
        numOutcomes = _numOutcomes;
        numTicks = _numTicks;
        feeDivisor = _feePerEthInAttoeth == 0 ? 0 : 1 ether / _feePerEthInAttoeth;
        denominationToken = _denominationToken;
        InitialReporterFactory _initialReporterFactory = InitialReporterFactory(controller.lookup("InitialReporterFactory"));
        participants.push(_initialReporterFactory.createInitialReporter(controller, this, _designatedReporterAddress));
        marketCreatorMailbox = owner;
        for (uint256 _outcome = 0; _outcome < numOutcomes; _outcome++) {
            shareTokens.push(createShareToken(_outcome));
        }
        require(denominationToken.approve(controller.lookup("CompleteSets"), APPROVAL_AMOUNT)); // Mert
        return true;
    }

    function createShareToken(uint256 _outcome) private onlyInGoodTimes returns (IShareToken) {
        return ShareTokenFactory(controller.lookup("ShareTokenFactory")).createShareToken(controller, this, _outcome);
    }

    function doInitialReport(uint256[] _payoutNumerators, bool _invalid) public onlyInGoodTimes returns (bool) {
        IInitialReporter _initialReporter = getInitialReporter();
        uint256 _timestamp = controller.getTimestamp();
        require(_initialReporter.getReportTimestamp() == 0);
        require(_timestamp > endTime);
        bool _isDesignatedReporter = msg.sender == _initialReporter.getDesignatedReporter();
        require(_isDesignatedReporter);
        bytes32 _payoutDistributionHash = derivePayoutDistributionHash(_payoutNumerators, _invalid);
        _initialReporter.report(msg.sender, _payoutDistributionHash, _payoutNumerators, _invalid);
        controller.getAugur().logInitialReportSubmitted(universe, msg.sender, this, _isDesignatedReporter, _payoutNumerators, _invalid);
        return true;
    }

    function finalize() public onlyInGoodTimes returns (bool) {
        require(winningPayoutDistributionHash == bytes32(0));

        require(getInitialReporter().getReportTimestamp() != 0);
        winningPayoutDistributionHash = participants[participants.length-1].getPayoutDistributionHash();
        universe.decrementOpenInterestFromMarket(shareTokens[0].totalSupply().mul(numTicks));
        finalizationTime = controller.getTimestamp();
        controller.getAugur().logMarketFinalized(universe);
        return true;
    }

    function getMarketCreatorSettlementFeeDivisor() public view returns (uint256) {
        return feeDivisor;
    }

    function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256) {
        if (feeDivisor == 0) {
            return 0;
        }
        return _amount / feeDivisor;
    }

    function withdrawInEmergency() public onlyInBadTimes onlyOwner returns (bool) {
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
        return true;
    }

    function getTypeName() public view returns (bytes32) {
        return "Market";
    }

    function getWinningPayoutDistributionHash() public view returns (bytes32) {
        return winningPayoutDistributionHash;
    }

    function isFinalized() public view returns (bool) {
        return winningPayoutDistributionHash != bytes32(0);
    }

    function getDesignatedReporter() public view returns (address) {
        return getInitialReporter().getDesignatedReporter();
    }

    function designatedReporterShowed() public view returns (bool) {
        return getInitialReporter().designatedReporterShowed();
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    function getMarketCreatorMailbox() public view returns (address) {
        return marketCreatorMailbox;
    }

    function isInvalid() public view returns (bool) {
        require(isFinalized());
        return getWinningReportingParticipant().isInvalid();
    }

    function getInitialReporter() public view returns (IInitialReporter) {
        return IInitialReporter(participants[0]);
    }

    function getInitialReporterAddress() public view returns (address) {
        return address(participants[0]);
    }

    function getReportingParticipant(uint256 _index) public view returns (IReportingParticipant) {
        return participants[_index];
    }

    function getWinningReportingParticipant() public view returns (IReportingParticipant) {
        return participants[participants.length-1];
    }

    function getWinningPayoutNumerator(uint256 _outcome) public view returns (uint256) {
        require(isFinalized());
        return getWinningReportingParticipant().getPayoutNumerator(_outcome);
    }

    function getUniverse() public view returns (IUniverse) {
        return universe;
    }

    function getFinalizationTime() public view returns (uint256) {
        return finalizationTime;
    }

    function getNumberOfOutcomes() public view returns (uint256) {
        return numOutcomes;
    }

    function getNumTicks() public view returns (uint256) {
        return numTicks;
    }

    function getDenominationToken() public view returns (ERC20) {
        return denominationToken;
    }

    function getShareToken(uint256 _outcome) public view returns (IShareToken) {
        return shareTokens[_outcome];
    }

    function getNumParticipants() public view returns (uint256) {
        return participants.length;
    }

    function derivePayoutDistributionHash(uint256[] _payoutNumerators, bool _invalid) public view returns (bytes32) {
        uint256 _sum = 0;
        uint256 _previousValue = _payoutNumerators[0];
        require(_payoutNumerators.length == numOutcomes);
        for (uint256 i = 0; i < _payoutNumerators.length; i++) {
            uint256 _value = _payoutNumerators[i];
            _sum = _sum.add(_value);
            require(!_invalid || _value == _previousValue);
            _previousValue = _value;
        }
        if (_invalid) {
            require(_previousValue == numTicks / numOutcomes);
        } else {
            require(_sum == numTicks);
        }
        return keccak256(abi.encodePacked(_payoutNumerators, _invalid));
    }

    function isContainerForShareToken(IShareToken _shadyShareToken) public view returns (bool) {
        return getShareToken(_shadyShareToken.getOutcome()) == _shadyShareToken;
    }

    function isContainerForReportingParticipant(IReportingParticipant _shadyReportingParticipant) public view returns (bool) {
        // Participants is implicitly bounded by the floor of the initial report REP cost to be no more than 21
        for (uint256 i = 0; i < participants.length; i++) {
            if (_shadyReportingParticipant == participants[i]) {
                return true;
            }
        }
        return false;
    }

    function onTransferOwnership(address _owner, address _newOwner) internal returns (bool) {
        controller.getAugur().logMarketTransferred(getUniverse(), _owner, _newOwner);
        return true;
    }

    function assertBalances() public view returns (bool) {
        // Escrowed funds for open orders
        uint256 _expectedBalance = 0;
        // Market Open Interest. If we're finalized we need actually calculate the value
        if (isFinalized()) {
            IReportingParticipant _winningReportingPartcipant = getWinningReportingParticipant();
            for (uint256 i = 0; i < numOutcomes; i++) {
                _expectedBalance = _expectedBalance.add(shareTokens[i].totalSupply().mul(_winningReportingPartcipant.getPayoutNumerator(i)));
            }
        } else {
            _expectedBalance = _expectedBalance.add(shareTokens[0].totalSupply().mul(numTicks));
        }

        assert(denominationToken.balanceOf(this) >= _expectedBalance);
        return true;
    }
}
