#!/bin/bash

# This script is for creating a Multiplier3 circuit using circom and snarkjs using GROTH16 protocol
# It requires circom, snarkjs, and wget to be installed
# It also requires the powersOfTau28_hez_final_10.ptau file to be downloaded from the hermez website
# It will generate a Multiplier3 circuit, a verification key, and a solidity verifier contract
# To run this ZKSNARKS operations script, your working directory shoould be /week1/Q2/

cd contracts/circuits

# Create a new directory for the Multiplier3 circuit
mkdir Multiplier3

# Check if the powersOfTau28_hez_final_10.ptau file exists
if [ -f ./powersOfTau28_hez_final_10.ptau ]; then
    # If it exists, skip the download step
    echo "powersOfTau28_hez_final_10.ptau already exists. Skipping."
else
    # If it does not exist, download it from the hermez website
    echo 'Downloading powersOfTau28_hez_final_10.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_10.ptau
fi

# Compile the Multiplier3.circom file using circom
echo "Compiling Multiplier3.circom..."

# The --r1cs flag generates a rank-1 constraint system file
# The --wasm flag generates a WebAssembly file
# The --sym flag generates a symbolic information file
# The -o flag specifies the output directory
circom Multiplier3.circom --r1cs --wasm --sym -o Multiplier3

# Display some information about the generated r1cs file using snarkjs
npx snarkjs r1cs info Multiplier3/Multiplier3.r1cs

# Start a new zkey file and make a contribution using snarkjs and the powersOfTau28_hez_final_10.ptau file
npx snarkjs groth16 setup Multiplier3/Multiplier3.r1cs powersOfTau28_hez_final_10.ptau Multiplier3/circuit_0000.zkey

# The --name flag specifies the name of the contributor
# The -v flag enables verbose mode
# The -e flag specifies the entropy source for the contribution
npx snarkjs zkey contribute Multiplier3/circuit_0000.zkey Multiplier3/circuit_final.zkey --name="1st Contributor Name" -v -e="random text"

# Export the verification key from the final zkey file as a JSON file using snarkjs
npx snarkjs zkey export verificationkey Multiplier3/circuit_final.zkey Multiplier3/verification_key.json

# Generate a solidity contract for verifying proofs using the final zkey file and snarkjs
npx snarkjs zkey export solidityverifier Multiplier3/circuit_final.zkey ../Multiplier3Verifier.sol

# Go back to the root directory
cd ../..

cd contracts/circuits/Multiplier3

# Create input file
echo "Create inputs for Multiplier3 circuit in Multiplier3_input.json"
echo "{\"a\": \"3\", \"b\": \"4\", \"c\": \"5\"}" > ./Multiplier3_input.json

# Calculate witness
echo "Generate witness from Multiplier3_input.json, using Multiplier3.wasm, saving to Multiplier3_witness.wtns"
echo "[PROFILE] Witness generation time: %E";
    npx node Multiplier3_js/generate_witness.js Multiplier3_js/Multiplier3.wasm ./Multiplier3_input.json \
        Multiplier3_js/Multiplier3_witness.wtns

# Create a proof for our witness
echo "Starting proving that we have a witness (our Multiplier3_input.json in form of Multiplier3_witness.wtns)"
echo "Proof and public signals are saved to Multiplier3_proof.json and Multiplier3_public.json"
echo "[PROFILE] Prove time: %E";
    npx snarkjs groth16 prove ./circuit_final.zkey Multiplier3_js/Multiplier3_witness.wtns \
        Multiplier3_js/Multiplier3_proof.json \
        Multiplier3_js/Multiplier3_public.json

# Verify our proof
echo "Checking proof of knowledge of private inputs for Multiplier3_public.json using Multiplier3_verification_key.json"
echo "[PROFILE] Verify time: %E";
    npx snarkjs groth16 verify ./verification_key.json \
        Multiplier3_js/Multiplier3_public.json \
        Multiplier3_js/Multiplier3_proof.json

# Check the sizes and performance of proof, verification and witness files
echo "Output sizes of client's side files":
echo "[PROFILE]" `du -kh "Multiplier3_js/Multiplier3.wasm"`
echo "[PROFILE]" `du -kh "Multiplier3_js/Multiplier3_witness.wtns"`
