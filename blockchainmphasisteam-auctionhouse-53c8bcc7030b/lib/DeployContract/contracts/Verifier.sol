// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.4.14;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point p) pure internal returns (G1Point) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function addition(G1Point p1, G1Point p2) internal returns (G1Point r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 6, 0, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point p, uint s) internal returns (G1Point r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 7, 0, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] p1, G2Point[] p2) internal returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point a1, G2Point a2, G1Point b1, G2Point b2) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2,
            G1Point d1, G2Point d2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }
    function verifyingKey() pure internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([0xa36a976ffcf49f9075866c9f0311e885fe53189d5ad3f11ec99f9a0b9307af1, 0x2e92e529a959ad9f206835907b52180b2edf39dcf019cba3108a0899c9672a06], [0x2358b923a1b4f8136e7b188fb987d693a187c0fc02bb3d655598ef9a7f5cb291, 0x21477c5c133573be583721eaa2612ac19e389321f4712065707f09fc8fa9d88]);
        vk.B = Pairing.G1Point(0x5e2bb3f13898c343d6aa1080c5635090f848e868f3836d1b9b9f061fa8816e6, 0x220e92084b4fb9526328c8bbfe8f8e009810149be69cf99dd87db78d2d9b35c8);
        vk.C = Pairing.G2Point([0x1795529724bd498d61849646a6ba3bf19881e20a525de71ecd311c3094abe35b, 0x95209616a75f3c8e4ea5ae8d3fcf782cd0eca28d93cc0215d6234f5b5e91aa3], [0x87008c85bb001486472fee07cec43e016a5f90beebd8327d71e4f9250d759f2, 0xda9af6481baa16a52b0f6c04d8f38897d8b4144ce65893513be3f93e438390b]);
        vk.gamma = Pairing.G2Point([0x54ba8020206da302752c95b0093d947b7cd963f490f2ce5beb3f18ce5013b6b, 0x2cebec596db18dc7e3e9c1720cda9f985a6577ad21bebc2aac4d5e483508db94], [0x1479978daef2a7e1bf433137584e5f85f5a0e6001af36aeaf291f30f06a2a1cd, 0xa596b7c987d90cdeadf68fb482106b0017dbdce6df85a66bb8a9a9dcb1699d]);
        vk.gammaBeta1 = Pairing.G1Point(0x109cd3de96499d502f3eb393d585590bbd48904687cf10a3078c704f4cccc427, 0x26227600456ad6503fac16215e33d1d575dc60dc1cf77a7a56b7f8158ff059e3);
        vk.gammaBeta2 = Pairing.G2Point([0x2af745708d9a3410f34b822e21ac47d4413f323b88ffebf979dc4f587fc91e33, 0x199d8f99b9c0ed8b2dcd35caa14e718c1a8b085a0c085ef0c670939d6208f5f2], [0x27e5bbb405e69ef90480d07dba9ce8825b57d5d92d2c500896478dbf18a2f387, 0x1057261a1176a64d89071e310110f5dc626951f8e5a8d1b27eee184be026e99]);
        vk.Z = Pairing.G2Point([0xd6f3dc9f9fdb41e9ecc4c074886cd52409163f41f57674f19bbc7e00bdd3b3f, 0x1d37f3a9fbce6bdda8749685b78c53fb4765e01a9652d004702f3ca6796eb67b], [0x227cb3109d672faf640736b2e39cf5d599707e20fa561daaa6b7cb8e2966a3f0, 0x2a46d51f05de9228f81b98ab0ee12e5741798b4fcebd774c11325352ec6a7710]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x1fdadea0d4cf3bb89e14adc19a50a1cc1b83595538d178f5b3c4661197c7a98b, 0x2e67eca0699b921181d185c1a0636c1b3f0b05cf6949189cc3cd420494c3b66f);
        vk.IC[1] = Pairing.G1Point(0xc33abdfe34702f8c1248cc363ca709294126af82311b8b5e2e8174e4bc3cabf, 0x1ae8c94922de76111cea33213427af30d568bea8a13077111d05519e91784f0e);
        vk.IC[2] = Pairing.G1Point(0x24eedeeed361da696cbf85e5c3e9b737f2c5b6a84b287f1d10e9c5d44d8f0830, 0x2502a159a403ceb78238502ab10b99320d2500e7578846935f126c39dc557ff3);
        vk.IC[3] = Pairing.G1Point(0xfd0c4e375bfaf51db1e0ea64b0ded242176d0e2c1e4486d6cf8327ce1e72bce, 0xd7fb076ea8650a07eb9a0fee4ba11f881d4639e18cc6e87c053aa7cca8b8c35);
        vk.IC[4] = Pairing.G1Point(0x2cb93ff8bc07d327cd00e4c601841c57892919e5c502acc12be16588cb5e374c, 0x2fe58176bbf2c5dde8955f6d66ab913bfc79512f47a908d1bc731a06b5764828);
        vk.IC[5] = Pairing.G1Point(0x290b34fd27f4e1e998a836a12dd41b9427a97edc47033bbe0a19ea578e3b2a79, 0x1d9d38789de8298b25447d1a5fe022eed8db9dadb7e17cd59471279b6db3da8);
    }
    function verify(uint[] input, Proof proof) internal returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.addition(vk_x, Pairing.addition(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.addition(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    event Verified(string s);
    function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[5] input
        ) public returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            emit Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }
}
