// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {FlareVtpmAttestation} from "../contracts/FlareVtpmAttestation.sol";
import {OidcSignatureVerification} from "../contracts/verifiers/OidcSignatureVerification.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script, console} from "forge-std/Script.sol";

contract FlareVtpmAttestationScript is Script {
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    string hwmodel = vm.envString("HWMODEL");
    string swname = vm.envString("SWNAME");
    string imageDigest = vm.envString("IMAGE_DIGEST");
    string iss = vm.envString("ISS");
    bool secboot = vm.envBool("SECBOOT");

    FlareVtpmAttestation flareVtpmImplementation;
    FlareVtpmAttestation flareVtpm;
    OidcSignatureVerification oidcVerifierImplementation;
    OidcSignatureVerification oidcVerifier;

    function deploy() public {
        // Starting the broadcast of transactions from the deployer account
        vm.startBroadcast(deployerPrivateKey);

        address deployer = vm.addr(deployerPrivateKey);

        // Deploy the FlareVtpmAttestation implementation
        flareVtpmImplementation = new FlareVtpmAttestation();
        console.log("FlareVtpmAttestation implementation deployed at:", address(flareVtpmImplementation));

        // Prepare initialization data for FlareVtpmAttestation
        bytes memory flareVtpmInitData = abi.encodeWithSelector(
            FlareVtpmAttestation.initialize.selector,
            deployer,
            hwmodel,
            swname,
            imageDigest,
            iss,
            secboot
        );

        // Deploy the FlareVtpmAttestation proxy
        ERC1967Proxy flareVtpmProxy = new ERC1967Proxy(address(flareVtpmImplementation), flareVtpmInitData);
        flareVtpm = FlareVtpmAttestation(address(flareVtpmProxy));
        console.log("FlareVtpmAttestation proxy deployed at:", address(flareVtpm));

        // Log that the base configuration has been set during initialization
        console.log("Base quote configuration set with:");
        console.log("  Hardware Model:", hwmodel);
        console.log("  Software Name:", swname);
        console.log("  Image Digest:", imageDigest);
        console.log("  Issuer:", iss);
        console.log("  Secure Boot:", secboot);

        // Deploy the OidcSignatureVerification implementation
        oidcVerifierImplementation = new OidcSignatureVerification();
        console.log("OidcSignatureVerification implementation deployed at:", address(oidcVerifierImplementation));

        // Prepare initialization data for OidcSignatureVerification
        bytes memory oidcInitData = abi.encodeWithSelector(
            OidcSignatureVerification.initialize.selector,
            deployer
        );

        // Deploy the OidcSignatureVerification proxy
        ERC1967Proxy oidcVerifierProxy = new ERC1967Proxy(address(oidcVerifierImplementation), oidcInitData);
        oidcVerifier = OidcSignatureVerification(address(oidcVerifierProxy));
        console.log("OidcSignatureVerification proxy deployed at:", address(oidcVerifier));

        // Set the token type verifier to the OidcSignatureVerification contract
        flareVtpm.setTokenTypeVerifier(address(oidcVerifier));
        console.log("FlareVtpmAttestation token type verifier set to OidcSignatureVerification");

        vm.stopBroadcast();
    }
}
