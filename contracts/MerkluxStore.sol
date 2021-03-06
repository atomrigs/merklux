pragma solidity ^0.4.24;

import {PatriciaTree} from "solidity-patricia-tree/contracts/tree.sol";
import "openzeppelin-solidity/contracts/ownership/Secondary.sol";
import "openzeppelin-solidity/contracts/access/Roles.sol";
import "../libs/bakaoh/solidity-rlp-encode/contracts/RLPEncode.sol";


/**
 * @title MerkluxTree data structure for
 *
 */
contract MerkluxStore is Secondary {
    using PatriciaTree for PatriciaTree.Tree;
    using Roles for Roles.Role;
    string constant REDUCER = "&";

    PatriciaTree.Tree tree;

    constructor() public Secondary() {
    }

    function insert(bytes key, bytes value) public onlyPrimary {
        if (key.length > 1) {
            // Reducer cannot be overwritten through this function
            require(!(key[0] == byte(0) && key[1] == byte(38)));
        }
        tree.insert(key, value);
    }

    function setReducer(string _action, bytes32 _reducerHash) public onlyPrimary {
        tree.insert(_getReducerKey(_action), abi.encodePacked(_reducerHash));
    }

    function getReducer(string _action) public view returns (bytes32) {
        bytes32 _reducerHash;
        bytes memory _storedValue = tree.get(_getReducerKey(_action));

        if (_storedValue.length == 32) {
            for (uint i = 0; i < 32; i++) {
                _reducerHash |= bytes32(_storedValue[i] & 0xFF) >> (i * 8);
            }
            return _reducerHash;
        }
        else return bytes32(0);
    }

    function get(bytes key) public view returns (bytes) {
        return tree.get(key);
    }

    function getLeafValue(bytes32 valueHash) public view returns (bytes) {
        return tree.getValue(valueHash);
    }

    function getRootHash() public view returns (bytes32) {
        return tree.getRootHash();
    }

    /**
     * @dev
     * @return _reducerKey always starts with 0x0026
     */
    function _getReducerKey(string _action) private pure returns (bytes memory _reducerKey) {
        bytes memory _a = bytes(_action);
        _reducerKey = new bytes(_a.length + 2);
        _reducerKey[0] = byte(0);
        _reducerKey[1] = byte(38);
        for (uint i = 2; i < _reducerKey.length; i++) _reducerKey[i] = _a[i - 2];
    }
}
