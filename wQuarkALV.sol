// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@cryptolink/contracts/message/MessageClient.sol";
import "./Libraries.sol";


contract wQuarkALV is MessageClient, Context, Ownable, Pausable {

    address private _quarkTokenAddress;
    IERC20 private _quarkToken;

    constructor(
        address quarkTokenAddress
    ) {
        require(quarkTokenAddress != address(0), "Cannot be zero address!");
        _quarkTokenAddress = quarkTokenAddress;
        _quarkToken = IERC20(_quarkTokenAddress);
    }

    function bridge(
        uint _destChainId,
        address _recipient,
        uint _amount
    ) external onlyActiveChain(_destChainId) whenNotPaused {
        SafeERC20.safeTransferFrom(_quarkToken, msg.sender, address(this), _amount);
        _sendMessage(_destChainId, abi.encode(_recipient, _amount));
    }

    function messageProcess(
        uint, 
        uint _sourceChainId, 
        address _sender, 
        address, uint, 
        bytes calldata _data
    ) external override  onlySelf(_sender, _sourceChainId) whenNotPaused {
        (address _recipient, uint _amount) = abi.decode(_data, (address, uint));
        SafeERC20.safeTransferFrom(_quarkToken, address(this), _recipient, _amount);
    }

    function emergencyRecover() public onlyOwner {
        uint256 contractTokenBalance = _quarkToken.balanceOf(address(this));
        SafeERC20.safeTransfer(_quarkToken, msg.sender, contractTokenBalance);
        pause();
    }

    function recoverALV() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause() public onlyOwner {
        super._pause();
    }

    function unpause() public onlyOwner {
        super._unpause();
    }

}