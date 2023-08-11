export interface ReadPromptOptions {
  writer: Deno.Writer;
  reader: Deno.Reader;
  bufferFactory: () => Uint8Array;
  decoder: TextDecoder;
  encoder: TextEncoder;
}

const enum Char {
  LF = 10,
  CR = 13,
}

const DEFAULT_MESSAGE = "#? ";
const EOL = "\n";
const EOLS: Uint8Array = Uint8Array.of(Char.CR, Char.LF);

function defaultOptions(
  options?: Partial<ReadPromptOptions>,
): ReadPromptOptions {
  return {
    writer: Deno.stderr,
    reader: Deno.stdin,
    bufferFactory: () => new Uint8Array(255),
    decoder: new TextDecoder(),
    encoder: new TextEncoder(),
    ...options,
  };
}

async function* readByte(reader: Deno.Reader): AsyncGenerator<number> {
  const p = new Uint8Array(1);
  while (await reader.read(p) !== null) {
    const [byte] = p;
    if (EOLS.includes(byte)) {
      break;
    }
    yield byte;
  }
}

export class Prompt {
  #message;

  #decoder;

  #encoder;

  #writer;

  #reader;

  #bufferFactory;

  static fromString(
    message: string,
    options?: Partial<ReadPromptOptions>,
  ) {
    return new Prompt(message, defaultOptions(options));
  }

  static withDefaultString(options?: Partial<ReadPromptOptions>) {
    return Prompt.fromString(DEFAULT_MESSAGE, options);
  }

  constructor(
    message: string,
    { encoder, decoder, writer, reader, bufferFactory }: ReadPromptOptions,
  ) {
    this.#message = encoder.encode(message);
    this.#encoder = encoder;
    this.#decoder = decoder;
    this.#writer = writer;
    this.#reader = reader;
    this.#bufferFactory = bufferFactory;
  }

  async print(...content: unknown[]) {
    await this.#print(content.join(" "));
  }

  async printLn(...content: unknown[]) {
    await this.#print(content.join(" "), EOL);
  }

  async readString(): Promise<string> {
    await this.#writer.write(this.#message);
    const buffer = this.#bufferFactory();
    let i = 0;
    for await (const byte of readByte(this.#reader)) {
      if (i >= buffer.length) {
        throw new Error("Buffer overflow");
      }
      buffer[i++] = byte;
    }
    return this.#decoder.decode(buffer);
  }

  async readInt(radix?: number): Promise<number> {
    return parseInt(await this.readString(), radix);
  }

  async select<T>(values: readonly T[]): Promise<T> {
    let choice: number;
    await this.printLn(
      values.map((v, i) => `${i + 1}) ${v}`)
        .join(EOL),
    );
    do {
      choice = await this.readInt();
    } while (0 > choice || choice > values.length);
    return values[choice - 1];
  }

  async #print(...content: string[]) {
    await this.#writer.write(this.#encoder.encode(content.join("")));
  }
}
