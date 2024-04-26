using Concentus.Structs;
using Concentus.Enums;
using Godot;
using System;

partial class OpusCompression : Node
{
	static OpusEncoder encoder = new OpusEncoder(48000, 1, OpusApplication.OPUS_APPLICATION_VOIP);
	static OpusDecoder decoder = new OpusDecoder(48000, 1);

	static int frameSize = 480;
	public static byte[] encode(float[] input)
	{
		// Output buffer - max opus packet size is 1275
		byte[] outputBuffer = new byte[1275];
		
		// Encode the float PCM data directly
		int bytesEncoded = encoder.Encode(input, 0, frameSize, outputBuffer, 0, outputBuffer.Length);

		byte[] encodedAudio = new byte[bytesEncoded];
		Array.Copy(outputBuffer, encodedAudio, bytesEncoded);

		return encodedAudio;
	}

	public static float[] decode(byte[] opusData)
	{
		// Prepare the output buffer - assuming a max packet duration of 120ms; adjust accordingly
			float[] outputBuffer = new float[5760];
			
			// Decode the audio
			int samplesDecoded = decoder.Decode(opusData, 0, opusData.Length, outputBuffer, 0, frameSize, false);

			// Adjust the output buffer to match the number of decoded samples
			float[] decodedAudio = new float[samplesDecoded];
			Array.Copy(outputBuffer, decodedAudio, samplesDecoded);

			return decodedAudio;
	}
}
