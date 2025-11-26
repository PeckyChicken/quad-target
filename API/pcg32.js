export class PCG32 {
    constructor(seed = 0) {
        this.state = BigInt(seed) || 0n;
        this.inc = 1442695040888963407n; // default increment
    }

    next() {
        const oldState = this.state;
        this.state = oldState * 6364136223846793005n + this.inc;
        const xorshifted = Number(((oldState >> 18n) ^ oldState) >> 27n) >>> 0;
        const rot = Number(oldState >> 59n) & 31;
        return (xorshifted >>> rot) | (xorshifted << ((-rot) & 31)) >>> 0;
    }

    nextFloat() {
        return this.next() / 0x100000000;
    }

    nextInt(min, max) {
        return Math.floor(this.nextFloat() * (max - min + 1)) + min;
    }
}
