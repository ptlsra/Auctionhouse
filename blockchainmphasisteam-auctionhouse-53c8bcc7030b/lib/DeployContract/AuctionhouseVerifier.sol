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
        vk.A = Pairing.G2Point([0x11f8381d5beb5469e29f30a2f3401480ccd59460bc845225a2f2e7885fc8cba8, 0x114a4aff5a918f509726aa1093fe144f1b17fb19d4cea6c6471b231d9fd7c390], [0x15e47862752dc080281c52b8c87ffdaebcb7b392c1832075a6cfdf11e120a408, 0x2e9cf2018f227824515ae4caf4bf091547da414fb43fa81fa3f1a172cbcc9077]);
        vk.B = Pairing.G1Point(0x11df7bb5c34b7c24e51db4f44c6df291e992e2380d00787208f0cb8169b10a27, 0x564a20e8b9e201cdf3f1cd83be27851dd3e02a64e417259db7ed85485d23037);
        vk.C = Pairing.G2Point([0x169160a22fa190954d68b932132ca8f98322168fdbb2ee4641f789180bd529de, 0x10a6c7a815219a1c44416e179a21b1b59db5cc6c9f640682b8a6acc4ba7c4b0c], [0xc48810db6b07d9ab76ebce21c69cf91ebc1a9203724795ca8f65f18438eef2d, 0x152db42b59f4269a81755b1e1e73b3a8299330fd119c701d4bf6bcdb79080bfe]);
        vk.gamma = Pairing.G2Point([0x17f0caa91bf3b311db1f0182672c4dfe48e0bdc5553a0ec301b528e1a027ed2e, 0x2ddb57f7965bb9e35b6a3d1f076d4f364cd749464d1381b7a9b394f8a30ea66b], [0x10b7b044b0bb3cebdadf6e89b0c8b22a1f1826e7b1fcfad8ddc52eccbfe3047e, 0x266777c6b80b85c4701a40c357a79150958f86fb8cd7b0bfd41e120863f91a1b]);
        vk.gammaBeta1 = Pairing.G1Point(0x2968f8ad105b59654a32fc9bcaa09526792b554725a2c179f8ec827b4f41542d, 0x16fa511be29bd12b6877ebad07bb784131120338ac0981c413a5500b3da74861);
        vk.gammaBeta2 = Pairing.G2Point([0x1d7b97f76bb47805ac38489415d2be033b8583a57e2fc816af39ab1249135e23, 0x2e2f5132f7e4ae2c6770b91e1eeed674e325eb53b37caa5e7f0809062001a8c6], [0x3004b4cf44b8ada455382e82ef7344b8bc6ae4a5cb5aa5ff7ccd9401e6ef2f36, 0x19e18c52dfa31857cc1f7cdedfefcd1e297e7ab64e35d6db685e54a59526d39d]);
        vk.Z = Pairing.G2Point([0x2568869063f8de6e53c6d1a6105cb48208eedbf72c41ae8a2a67bf52ee392199, 0x2d407870254d6e38dc6de90acd721beb2edace946fe412440fb4667bad24893f], [0x2de924ea2bfe0e2f08d41dc52bdf2ae522633933008466006e9151cdb6ab1422, 0x5873a188ae612ddf8a53b5c928f3aca470469bc8ccbd9c560e6ffb5672136ea]);
        vk.IC = new Pairing.G1Point[](5);
        vk.IC[0] = Pairing.G1Point(0x113581b106cbcd01c01e8f08139443c1fb051466ef0ec48907c13eaf0c2d9ada, 0x894bc83d618f6f9a4c39c0a99c54458d4b259b3f8e21919dc9b4fe8d6acf9fb);
        vk.IC[1] = Pairing.G1Point(0x17fe7262a281c0ee727eae0230ed7c36f6382fb83dc4a70890f516c06b59368b, 0xc737abe6c65cb1432ef3a7dd9bc827e3c95e3bdc5052d042ba76245c3ed7d38);
        vk.IC[2] = Pairing.G1Point(0x111346e5d42e5ff999275de8943b79c83953a917137a079755ad0d77bc1e4a64, 0x2a0a67527ecfdbcd4f4f21ac522cb2592caeb9b253d7acd07ad6199233cc5260);
        vk.IC[3] = Pairing.G1Point(0x1966a4757aa011e2d23ce0fe80b24d9ba4a5541bd6b408e2d154d442b0ca3baa, 0x2b37f07c174394efd30f80f0b80255787bfbdfd087607139084b47edc4299ac6);
        vk.IC[4] = Pairing.G1Point(0x2702e7bff86b9d81e00f5077188f9d59aa85bc43e6956822aa68766448b731c2, 0x22a5c9a0f7cc0e68558e7ea8ca15c1cc6600dab82d9dacd9672b77f62c97ce40);
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
