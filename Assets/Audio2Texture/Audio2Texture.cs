using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Audio2Texture : MonoBehaviour {
	[Range(2, 512)]
	public int resolution = 512; // resolution of audio Sample Size and size of texture

	public float rmsValue; // root means squared, average audio level
	public float dbValue; // decibels values, loudness
	public float pitchValue; // pitch is pitch/frequency

	public float backgroundIntensity; // to modulate anything with valaue 0-1
	public Material backgroundMat; // material of thing you want audio reactive
	public Color minColor; // min color of the audio reactive object
	public Color maxColor; // max color of the audio reactive object

	public float smoothSpeed = 10.0f; // how fast value falls back down, smoothing speed
	public float keepPercent = 0.5f;  

	private AudioSource source; // Audio Source
	private float[] samples; // array for samples in analysis
	private float[] spectrum; //array for spectrum in analysis
	private float sampleRate; // sampleRate 

	public Texture2D texture;

	// Use this for initialization
	void Start () 
	{
		texture = new Texture2D(512, 512);
		GetComponent<Renderer>().material.mainTexture = texture;
		source = GetComponent<AudioSource> (); //  get the sauce
		samples = new float[resolution]; // set all the things up...
		spectrum = new float[resolution]; //
		sampleRate = AudioSettings.outputSampleRate; 
	}

	void Update () 
	{
		AnalyseSound (); // Analyse sound first
	}

	void AnalyseSound() // analyse the sound 
	{
		source.GetOutputData (samples, 0);

		int i = 0;
		float sum = 0;
		for (; i < resolution; i++)
		{
			sum = samples[i] * samples[i];
		}
		rmsValue = Mathf.Sqrt(sum / resolution); 
		dbValue = 20.0f * Mathf.Log10(rmsValue / 0.1f); 
		source.GetSpectrumData(spectrum, 0 , FFTWindow.BlackmanHarris); 

		float maxV = 0;
		var maxN = 0;
		for (i = 0; i < resolution; i++)
		{
			if (!(spectrum [i] > maxV) || !(spectrum [i] > 0.0f))
				continue;
			maxV = spectrum [i];
			maxN = i;
		}

		for (int y = 0; y < texture.height; y++) 
		{
			for (int x = 0; x < texture.width; x++) 
			{
				float point = (spectrum[x]) * 256.0f;
//				float audioSignal = (spectrum [x]);
//				//audioSignal = (audioSignal * 0.5f + 0.5f) * 254.0f;
				Color color = new Color(point,point,point);
				//texture.SetPixel(x, y, Color.white*point);
				texture.SetPixel(x, y, color);
			}
		}
		texture.Apply ();

		float freqN = maxN;

		if (maxN > 0 && maxN < resolution - 1) 
		{
			var dL = spectrum [maxN - 1] / spectrum [maxN];
			var dR = spectrum [maxN + 1] / spectrum [maxN];
			freqN += 0.5f * (dR * dR - dL * dL);
		}
		pitchValue = freqN * (sampleRate / 2) / resolution;
	}
}

