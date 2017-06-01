/*
Expose only a subset of SignalBank's public members
Extend the class with signal setters and getters for integration with Numpy
arrays.
*/
namespace loudness{
class SignalBank {

public:
    SignalBank();
    ~SignalBank();
    void initialize(int nSources, int nEars, int nChannels, int nSamples, int fs);
    inline int getNSources();
    inline int getNEars();
    inline int getNChannels();
    inline int getNSamples();
    inline int getNTotalSamples();
    int getFs();
    inline void setSample(int source, int ear, int channel, int sample, Real value);
    inline Real getSample(int source=0, int ear=0, int channel=0, int sample=0) const;
    inline void setCentreFreq(int channel, Real freq);
    inline Real getCentreFreq(int channel) const;
    inline bool getTrig();
    inline void setTrig(bool trig);
    void reset();
    void zeroSignals();
    void setFrameRate(Real frameRate);
    void getFrameRate() const;
    void setChannelSpacingInCams(Real channelSpacingInCams);
    void aggregate();
    
    %extend {

        PyObject* getSignal(int source, int ear, int channel)
        {
            if (! loudness::isPositiveAndLessThanUpper(source, $self -> getNSources()))
                source = 0;
            if (! loudness::isPositiveAndLessThanUpper(ear, $self -> getNEars()))
                ear = 0;
            if (! loudness::isPositiveAndLessThanUpper(channel, $self -> getNChannels()))
                channel = 0;
            const Real* ptr;
            ptr = $self -> getSignalReadPointer(source, ear, channel, 0);
            npy_intp dims[1] = {$self -> getNSamples()}; 
            return PyArray_SimpleNewFromData(1, dims, NPY_DOUBLE, (void*)ptr);
        }

        PyObject* getSignals()
        {
            const Real* ptr;
            ptr = $self -> getSignalReadPointer(0, 0, 0);
            npy_intp dims[4] = {$self -> getNSources(),
                                $self -> getNEars(),
                                $self -> getNChannels(),
                                $self -> getNSamples()}; 
            return PyArray_SimpleNewFromData(4, dims, NPY_DOUBLE, (void*)ptr);
        }

        PyObject* getAggregatedSignals()
        {
            const RealVec& vec = $self -> getAggregatedSignals();
            long long int numFrames = vec.size() / $self -> getNTotalSamples();
            npy_intp dims[5] = {numFrames,
                                $self -> getNSources(),
                                $self -> getNEars(),
                                $self -> getNChannels(),
                                $self -> getNSamples()}; 
            return PyArray_SimpleNewFromData(5, dims, NPY_DOUBLE, (void*)vec.data());
        }

        PyObject* getCentreFreqs()
        {
            const Real* ptr = $self -> getCentreFreqsReadPointer(0);
            npy_intp dims[1] = {$self -> getNChannels()}; 
            return PyArray_SimpleNewFromData(1, dims, NPY_DOUBLE, (void*)ptr);
        }

        void setSignal(int source, int ear, int channel, Real* data, int nSamples)
        {
            if (! loudness::isPositiveAndLessThanUpper(ear, $self -> getNSources()))
                source = 0;
            if (! loudness::isPositiveAndLessThanUpper(ear, $self -> getNEars()))
                ear = 0;
            if (! loudness::isPositiveAndLessThanUpper(channel, $self -> getNChannels()))
                channel = 0;
            Real* ptr = $self -> getSignalWritePointer(source, ear, channel, 0);
            int nSamplesToCopy = loudness::min(nSamples, $self -> getNSamples());
            for (int i = 0; i < nSamplesToCopy; ++i)
                ptr[i] = data[i];
        }

        void setSignals(Real* data, int nSources, int nEars, int nChannels, int nSamples)
        {  
            Real* ptr = $self -> getSignalWritePointer(0, 0, 0);
            int nSamplesToCopy = loudness::min(nSources*nEars*nChannels*nSamples,
                                               $self -> getNTotalSamples());
            for (int i = 0; i < nSamplesToCopy; ++i)
                ptr[i] = data[i];
        }

        void setCentreFreqs(Real* data, int nChannels)
        {
            Real* ptr = $self -> getCentreFreqsWritePointer(0);
            int nFreqsToCopy = loudness::min(nChannels, $self -> getNChannels());
            for (int i = 0; i < nFreqsToCopy; i++)
                ptr[i] = data[i];
        }
    }
};
}
