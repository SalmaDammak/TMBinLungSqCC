# -*- coding: utf-8 -*-
"""
Created on Mon Apr 12 17:00:33 2021

@author: sdammak
"""
import sys
import numpy as np
import tensorflow as tf
import keras
import pandas as pd
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import random
import os
import sklearn.metrics as metrics
import matplotlib.pyplot as plt
import scipy.io as sio
  
def RunExperiment(sTrainDataCSVPath, sTestDataCSVPath, sResultsDir, iEpochs, dLearningRate, iBatchSize, sExperimentFolderName):
   
    # Set random number generators and determinisim controllers to allow for repeatability
    SEED = 123
    random.seed(SEED)
    np.random.seed(SEED)
    tf.random.set_seed(SEED)
    os.environ['TF_DETERMINISTIC_OPS'] = '1'
    os.environ['PYTHONHASHSEED'] = '0'

    # Prepare image datagenerators for training and testing 
    dfTrainData = pd.read_csv(sTrainDataCSVPath, dtype = 'str')
    dfTrainData = dfTrainData.rename(columns={'Var1': 'filename', 'Var2': 'class'})           

    dfTestData = pd.read_csv(sTestDataCSVPath,dtype = 'str')
    dfTestData = dfTestData.rename(columns={'Var1': 'filename', 'Var2': 'class'})
    
    train_batches = ImageDataGenerator(rescale = 1./255) \
        .flow_from_dataframe(
            dfTrainData,
            target_size=(224,224),   
            class_mode = "binary", 
            batch_size=iBatchSize, 
            shuffle = True)
    
    test_batches = ImageDataGenerator(rescale = 1./255) \
        .flow_from_dataframe(
            dfTestData,
            target_size=(224,224), 
            class_mode = "binary", 
            batch_size=iBatchSize, 
            shuffle = False)

    tOneTrainBatch  = train_batches.next() 
    fig1, ax1 = plt.subplots()
    ax1.imshow((tOneTrainBatch[0][0]))
    ax1.set_title('Train image: '  + sExperimentFolderName)
    fig1.savefig(sResultsDir + '\\Train image', dpi = 330)

    tOneTestBatch  = test_batches.next() 
    fig2, ax2 = plt.subplots()
    ax2.imshow((tOneTestBatch[0][0]))
    ax2.set_title('Test image: ' + sExperimentFolderName)    
    fig2.savefig(sResultsDir + '\\Test image', dpi = 330)

        
    # Load the model for transfer learning
    base_model = tf.keras.applications.vgg16.VGG16()  
    
    # Onto a fresh model, copy all layers but the last one
    model = Sequential()
    for layer in base_model.layers[:-1]:
        model.add(layer)
    
    # Set all layers except the last 5 to non-trainable (this plus the dense layer are the last 6 layers)
    for layer in model.layers:
        layer.trainable = False
        
    # Add the last layer, ie the one corresponding to my classes
    model.add(Dense(units=1, activation='sigmoid'))
		
    # Print model summary 
    model.summary()
 
    # Compile the model
    model.compile(optimizer=Adam(learning_rate = dLearningRate),
                  loss='binary_crossentropy', 
                  metrics=['accuracy'])
    
    # Add callback to allow early stopping
    # my_callback = keras.callbacks.EarlyStopping(monitor='val_loss', patience=3, mode='auto' )
    # [keras.callbacks.EarlyStopping(patience=3)]             
    
    # Fit to the training data, using the test data for validation
    history = model.fit(x=train_batches,
              steps_per_epoch=len(train_batches),              
              epochs=iEpochs,
              verbose=1,
              validation_data=test_batches,
              validation_steps=len(test_batches),
              callbacks= [keras.callbacks.EarlyStopping(monitor='val_loss', patience=3)])
    
	# Save the model
    tf.keras.models.save_model(model, sResultsDir + 'Model', save_format='h5')
	
	# Load the model (uncomment when necessary)
	# model2 = tf.keras.models.load_model('Model',custom_objects=None,compile=True)
    
    # Get predictions on the test set
    vsConfidences = model.predict(x=test_batches, steps=len(test_batches), verbose=1)
    viTruth = test_batches.classes
    GetErrorMetrics(sResultsDir, history, vsConfidences, viTruth) 
    
    # Save all important 'simple' variables
    sio.savemat(sResultsDir + 'Workspace_in_python.mat', 
                {'vsFilenames': test_batches.filenames,
                 'viTruth':viTruth,
                 'vsiConfidences': vsConfidences})
    
    return 

def GetErrorMetrics(sResultsDir, history, vsConfidences, viTruth):
    # I need to call this block of code twice for the model when I fine-tune, 
    # encapsulating it in a function makes it easy to do that with minimal 
    # repeated code.
    
    # Calculate and print some error metrics
    print(sResultsDir)
    print('AUC is: %0.2f' %(round(metrics.roc_auc_score(viTruth, vsConfidences), 2)))
    print('precision is: %d%s' %(round(100 * metrics.precision_score(viTruth, vsConfidences>0.5)),'%'))
    print('recall is: %d%s' %(round(100 * metrics.recall_score(viTruth, vsConfidences>0.5)),'%'))
                
# Plot history for accuracy and save the figure
    fig3, ax3 = plt.subplots()
    ax3.plot(history.history['accuracy'])
    ax3.plot(history.history['val_accuracy'])
    ax3.set_title('Model accuracy: ' + sExperimentFolderName)
    ax3.set_ylabel('accuracy')
    ax3.set_xlabel('epoch')
    fig3.legend(['train', 'test'], loc='upper left')
    fig3.savefig(sResultsDir + 'Accuracy history')
    
    # Plot history for loss and save the figure
    fig4, ax4 = plt.subplots()
    ax4.plot(history.history['loss'])
    ax4.plot(history.history['val_loss'])
    ax4.set_title('model loss: ' + sExperimentFolderName)
    ax4.set_ylabel('loss')
    ax4.set_xlabel('epoch')
    fig4.legend(['train', 'test'], loc='upper left')
    fig4.savefig(sResultsDir + 'Loss history')

    return

if __name__ == "__main__":
    sTrainDataCSVPath = sys.argv[1]
    sTestDataCSVPath =sys.argv[2]
    sResultsDir = sys.argv[3]
    
    # Set these arguments to the right type
    iEpochs = int(sys.argv[4])
    dLearningRate = float(sys.argv[5])
    iBatchSize = int(sys.argv[6])
    sExperimentFolderName = sys.argv[7]
    
    RunExperiment(sTrainDataCSVPath,
                  sTestDataCSVPath, 
                  sResultsDir, 
                  iEpochs, 
                  dLearningRate,
                  iBatchSize,
                  sExperimentFolderName)
'''
sTrainDataCSVPath = 'D:\\Users\\sdammak\\Experiments\\LUSC_DL\\0 Coded sections\\7 SP-008 [2021-07-12_13.46.43]\\Results\\01 Experiment Section\\SP-00_trainData.csv'
sTestDataCSVPath = 'D:\\Users\\sdammak\\Experiments\\LUSC_DL\\0 Coded sections\\7 SP-008 [2021-07-12_13.46.43]\\Results\\01 Experiment Section\\SP-008_testData.csv'
sResultsDir = os.getcwd()
epochs = 100
learning_rate = 0.001 
batch_size = 10
sExperimentFolderName = 'Direct'

RunExperiment(sTrainDataCSVPath, sTestDataCSVPath, sResultsDir, epochs, learning_rate, batch_size, sExperimentFolderName)
'''