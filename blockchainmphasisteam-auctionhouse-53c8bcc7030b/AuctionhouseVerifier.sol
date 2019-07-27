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

    //emit when verifyTx fails
    event Unverified(string);
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
        vk.A = Pairing.G2Point([0x2d637c0d36e5d4a4048951cdb2b18b172225abf690d46e83873295d49aed1ac, 0x1ad05d224ab478337b06969d67e7931425d240d411f9a7092a3fcafc59eb4c86], [0x2c99a4337bffdf26e71fef59fa879b816f09540fd7aa5058d1ebf9eca33a252a, 0x1d732a6b1c8528475cc45622f48dd116366a6318407923e1ed9d37672bb8c9af]);
        vk.B = Pairing.G1Point(0x10bd394b934b06c95bf0ff2e2bea1ed799a71fd974dc185daa061b4851ebb536, 0x2a381334f76ce201271bf52872094e0c994cdb7aa15b5c3500485335f17b893d);
        vk.C = Pairing.G2Point([0x284dea40c355cc65b972fbf101565067482224463e89204d910c115c486f1d57, 0x1af61de5271b554ee818a4679c40be9f8934d87f131d9cdb16bf8967cb664b90], [0x19d99fd65c2a433aa4b762546b1e5cdcb93294124f29f9e4728a2e0cf9be55fa, 0x2e192e89f2df0ef9a3265e1503a2b94dfb3fbbce128af4bfc583c407a232606c]);
        vk.gamma = Pairing.G2Point([0x3ad7f9c0f22278df376f0be88996f15e470e6807c5dbfc00702a5a862595c6a, 0x2e4b254c9920f2049d918780941ac4c040b3b6284863606964af5bb2326ac2e1], [0x1fa41271936020e1721dc8c4a87878b5093f35c72cfd2d6284fd08c8c03a3d46, 0x151b24e72dfb5fdc3d7e6254d68a823dac97147b9e931fca91323821ed70cc54]);
        vk.gammaBeta1 = Pairing.G1Point(0x2b3d240a96d63a28f72edb90f95a3dff10cccc4d61b3aafddc23afac6c19396e, 0x2e612a56e07e8caeb073c7cc30a3ce91ca7861025de40f9cf79c5429d3a759fd);
        vk.gammaBeta2 = Pairing.G2Point([0x2706ac195b40283d5237cbc59d912d8dcdd5a0e9927e9678bccd79ae96fb86d3, 0xb8239433d6e7a921bdefa24d52384bdbc2042cbccb56c3c4eefe4c1b66218af], [0x20c89a385d24c7e5de4cf1a4d4b9237468a90539c5d3415fcb375be726ce3a07, 0x904d1d86349abacf9366e8c6ebc75c78a96c17dc9376b0d08735d42729e6765]);
        vk.Z = Pairing.G2Point([0x6b2774a7cfb2b0e5dffdeaa1f80c4e61e5246e18aa0b36ee26f0797a9b466c7, 0x2c835c76fe6f6be4e77a56bb12bbf18345600f7918027be9862c9ef2ae8d06d8], [0x1cde83903dff9d6ff8fc6bf4cf73c5ceb305ec8b6a31c72fbb38af9386b26b1f, 0x2de14913623a38e336b6561210b69af304cc80dd5f5706e636facd6c775953dd]);
        vk.IC = new Pairing.G1Point[](5);
        vk.IC[0] = Pairing.G1Point(0x24c590e4f78c7f4b1ada66b4a13c93d3f58f1356410c3cabcbbce453c2833489, 0xc6f1cf90dcdea12d46c2fd627f11c93fd044ce75260f7bdc6e524bb1bb474d1);
        vk.IC[1] = Pairing.G1Point(0x2415dbf6d6e456c9933e547da1c108670e72242a18aef8bd8917a5419f14877a, 0xa059e0811eec89be8a39bc06144542384acc6d6dafc4560c5885a117a2a2b46);
        vk.IC[2] = Pairing.G1Point(0xd0adb0dfe3725f0f2fde0539a6d2326ff447bed94a0e4df25b329734dbacc24, 0x1e9500abf461f5b8efd4e11371cf7829aa7ca8c94ce8febc6a2bf5253821c8ab);
        vk.IC[3] = Pairing.G1Point(0x1a1a94a17a0976994604733d14d24b7845de1e5182c729673830d77e4dff5f76, 0x27190902134fad46990854139d5ce47a56a14c2ad521cee2c7f6f451ba3a55f0);
        vk.IC[4] = Pairing.G1Point(0xeb3aa31f4e7cfc4664d59620d803ac3fa455b08b54793d06256de8ea12b01d9, 0x1158d7f7ac85233e4bcd381d6382bb56fe0344485b6964e873410960308fdf03);
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
            uint[4] input
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
            emit Unverified("Transaction verification failed");
            return false;
        }
    }
}
