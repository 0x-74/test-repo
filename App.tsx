import { View, Text, Button, SafeAreaView, TextInput } from 'react-native'
import React, { useEffect, useState } from 'react'
import { NativeModules } from 'react-native'
import { Dropdown } from 'react-native-element-dropdown';

const { SpeechSynthesis } = NativeModules;

interface Voice {
  identifier: string;
  language: string;
  name: string;
  description: string;
}

const VOICE_TYPES = [
  { label: 'Enhanced', value: 'enhanced' },
  { label: 'Premium', value: 'premium' },
  { label: 'Compact', value: 'compact' },
  { label: 'Synthesis', value: 'synthesis' },
  { label: 'Personalvoice', value: 'personalvoice' },
  { label: 'Siri', value: 'siri' },
  { label: 'All', value: 'all' },
]

const App = () => {
  const [voiceList, setVoiceList] = useState<Voice[]>([]);
  const [selectedVoice, setSelectedVoice] = useState<Voice | null>(null);
  const [selectedVoiceType, setSelectedVoiceType] = useState<string>("");
  const [userText, setUserText] = useState<string>("");

  const handlePlay = async () => {

    if (!selectedVoice) {
      console.log('Nothing selected');
      return;
    }

    SpeechSynthesis.load(
      userText,
      0.5,
      0.0,
      10.0,
      selectedVoice['language'],
      selectedVoice['identifier'],
      (result: any) => {
        console.log(result.message);

        SpeechSynthesis.speak(userText, (speakResult: any) => {
          console.log(speakResult);
        });
      }
    );
  };

  const fetchPersonalVoice = async () => {
    try {
      const permissionGranted = await SpeechSynthesis.requestPersonalVoicePermission("testing")

      if (permissionGranted) {

        const localVoices = await SpeechSynthesis.listPersonalVoices("Debug message");

        console.log(`Found ${localVoices.length} personal voices`)

        setVoiceList(localVoices);
      }

    } catch (error) {
      console.log(error)
    }
  }

  const fetchSiriVoice = async () => {
    try {
      const localVoices = await SpeechSynthesis.listSiriVoices("Debug message");

      console.log(`Found ${localVoices.length} siri voices`)

      setVoiceList(localVoices);

    } catch (error) {
      console.log(error)
    }
  }

  const fetchVoices = async (voiceType: string) => {
    setVoiceList([])

    if (voiceType === "personalvoice") {
      fetchPersonalVoice()
    }
    else if (voiceType === "siri") {
      fetchSiriVoice()
    }
    else {
      try {
        const localVoices: Voice[] = await SpeechSynthesis.listAllVoices(voiceType);

        setVoiceList(localVoices)
        console.log(`Found ${localVoices.length} ${voiceType} voices`)

      } catch (error) {
        console.log(error)
      }
    }
  }

  return (
    <SafeAreaView style={{
      display: 'flex',
      marginTop: 80,
      marginHorizontal: 20,
      justifyContent: 'center'
    }}>
      <View style={{ marginBottom: 20 }}>
        <Text style={{ fontSize: 20, fontWeight: '500' }}>Select a Voice Type</Text>
        <Dropdown
          style={{ marginTop: 20 }}
          data={VOICE_TYPES}
          labelField="label"
          valueField="value"
          value={selectedVoiceType}
          onChange={item => {
            fetchVoices(item.value)
          }}
        />
      </View>

      <View style={{ marginBottom: 20 }}>

        <Text style={{ fontSize: 20, fontWeight: '500' }}>Pick a Voice</Text>

        <Dropdown
          style={{ marginTop: 20 }}
          data={voiceList}
          labelField="name"
          valueField="identifier"
          value={selectedVoice}
          onChange={item => {
            setSelectedVoice(item)
          }}
        />
      </View>
      <TextInput
        placeholder="Enter text to speak"
        value={userText}
        onChangeText={setUserText}
        style={{ borderWidth: 1, padding: 10, marginVertical: 10 }}
      />

      <Button title='Play Button' onPress={() => handlePlay()} />

    </SafeAreaView>
  )
}

export default App