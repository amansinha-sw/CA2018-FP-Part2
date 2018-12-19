// This program executes a typical Interval Join
#include <iostream>
#include <omp.h>
#include <time.h>
#include "intervalJoin.h"
using namespace std;


struct node 
{ 
	int middle;
    int *start,*end,*index; 
    int length;
    struct node *left, *right; 
}; 
   
struct node *newNode(int middle,int *start, int *end, int start_idx,int end_idx) 
{ 
	int i;
    struct node *temp =  (struct node *)malloc(sizeof(struct node)); 
    temp->middle=middle;
    temp->length=end_idx-start_idx+1;
    temp->start = (int*)malloc(temp->length*sizeof(int));
	temp->end = (int*)malloc(temp->length*sizeof(int));
	temp->index = (int*)malloc(temp->length*sizeof(int));
	for(i=0;i<temp->length;i++){
		temp->start[i]=start[start_idx+i];
		temp->end[i]=end[start_idx+i];
		temp->index[i]=start_idx+i;
	} 
	temp->left = temp->right = NULL; 
    return temp; 
}
   
void search(struct node *node, int start, int end, int index) 
{ 
	int i;
    if (node != NULL) 
    { 
    	for(i=0;i<node->length;i++){
    		if((node->start[i]<=start && start<=node->end[i]) || (node->start[i]<=end && end<=node->end[i]) || (node->start[i]<=start && end<=node->end[i]) || (node->start[i]>=start && end>=node->end[i])){
    			if(node->index[i]<start_index[index])
    				start_index[index]=node->index[i];
    			if(node->index[i]>end_index[index])
    				end_index[index]=node->index[i];  				
			}				
		}
    	if(start<=node->middle && node->middle<=end){
        	search(node->left,start,end, index); 
        	search(node->right,start,end, index);	
		}
        else if(end<node->middle)
        	search(node->left,start,end, index);
        else if(node->middle<start)
        	search(node->right,start,end, index);
    }
} 


struct node* make_tree(struct node* node,int *input_start, int *input_end,int array_start, int array_end){
	int i;
	int middle;
	int start_idx=-1,end_idx=-1;
	if(array_start<=array_end){
		middle=(input_start[array_start]+input_end[array_end])/2;
		for(i=array_start;i<=array_end;i++){
			if(input_start[i]<=middle && middle<=input_end[i]){
				if(start_idx==-1){
					start_idx=i;
				}
				end_idx=i;
			}
		}
		i=0;
		if(start_idx==-1 && end_idx==-1){
			while(input_end[i]<=middle)
				i++;
			start_idx=i-1;
			while(input_start[i]<middle)
				i++;
			end_idx=i-1;
		}
   
		node=newNode(middle, input_start,input_end,start_idx,end_idx);
	}
	if(start_idx>=0 && array_start>=0 && start_idx-1>=array_start)
		node->left=make_tree(node,input_start, input_end,array_start,start_idx-1);
	
			
	if(start_idx>=0 && end_idx+1<=array_end)
		node->right=make_tree(node,input_start, input_end,end_idx+1,array_end);
	
	return node;	
}


// This is the CPU version, please don't modify it
void intervalJoinCPU(int id)
{
	int i;
	struct node* root=NULL;
	int search_size= setB.length[id] * sizeof(int);
    start_index=(int*)malloc(search_size);
    end_index=(int*)malloc(search_size);
	
    root=make_tree(root,inStartA,inEndA,0,setA.length[id]-1);
    //inorder(root);
	#pragma omp parallel for
	for(i=0;i<setB.length[id];i++){
        start_index[i]=INT_MAX;
        end_index[i]=INT_MIN;
		search(root,inStartB[i],inEndB[i],i);
        outCPU_Begin[i]=start_index[i];
        outCPU_End[i]=end_index[i];
		//cout<<i<<endl;
    }
	int total_intersects=0;
        for(i=0;i<setB.length[id];i++){
                if(outCPU_Begin[i]!=INT_MAX && outCPU_End[i]!=INT_MIN){
                        total_intersects+=(outCPU_End[i]-outCPU_Begin[i]+1);
        }
    }
	//cout<<total_intersects<<endl;
	
	free(start_index);
	free(end_index);
}

// This is the CPU version, please don't modify it
void executeQuery_CPU(int id, int min_overlap)
{
	int index_first,index_last;
	int total_count=0;
	
	for(int i=0;i<setB.length[id];i++){
		if(outCPU_End[i]-outCPU_Begin[i]+1>=min_overlap){
			for(int k=outCPU_Begin[i];k<=outCPU_End[i];k++){
				index_first=abs(inStartA[k]-inStartB[i])%4;
				index_last=abs(inEndA[k]-inEndB[i])%4;
				
				if(inStringA[k][index_first]==inStringB[i][index_last]){
					outCPU_count[i]++;
				}
			}
			total_count+=outCPU_count[i];
			
		}
	}
}

/***	Implement your CUDA Kernel here	***/
__global__
void intervalJoinGPU()
{
}
/***	Implement your CUDA Kernel here	***/

/***    Implement your CUDA Kernel here ***/
__global__
void sort()
{
}
/***    Implement your CUDA Kernel here ***/

/***    Implement your CUDA Kernel here ***/
__global__
void executeQuery_GPU(int id)
{
}
/***    Implement your CUDA Kernel here ***/


int main()
{
	int i;
	timespec time_begin, time_end;
	int intervalJoinCPUExecTime, intervalJoinGPUExecTime;
	int cpuTotalTime=0,gpuTotalTime=0; 
	FILE *fpA, *fpB;
	read_Meta();
	
	fpA = fopen ("data/dataA.csv","r");
	fpB = fopen ("data/dataB.csv","r");
	
	for(i=0;i<setA.count;i++){
		init_from_csv(fpA, fpB, i);
		
		intervalJoinCPU(i);
		
		clock_gettime(CLOCK_REALTIME, &time_begin);
		executeQuery_CPU(i,2);
		
		clock_gettime(CLOCK_REALTIME, &time_end);
		intervalJoinCPUExecTime = timespec_diff_us(time_begin, time_end);
		cout << "CPU time for executing a typical Query = " <<  intervalJoinCPUExecTime / 1000 << "ms" << endl;
		cpuTotalTime+=intervalJoinCPUExecTime;
		
		randomize (inStartA,inEndA,inStringA, setA.length[i],4);
		
		
		//Do the required GPU Memory allocation here
		
		//Do the required GPU Memory allocation here
		
		//Configure the CUDA Kernel call here
		sort<<<1,1>>>(); // Lunch the kernel
		
		clock_gettime(CLOCK_REALTIME, &time_begin);
		executeQuery_GPU<<<1,1>>>(i);  // Lunch the kernel
		cudaDeviceSynchronize(); // Do synchronization before clock_gettime()
		//Copy back the result from GPU Memory to CPU memory array outGPU_count
		
		//Copy back the result from GPU Memory to CPU memory array outGPU_count
		
		clock_gettime(CLOCK_REALTIME, &time_end);
		intervalJoinGPUExecTime = timespec_diff_us(time_begin, time_end);
		cout << "GPU time for executing a typical Query = " << intervalJoinGPUExecTime / 1000 << "ms" << endl;
		cpuTotalTime+=intervalJoinGPUExecTime;
		
		if(checker(setB.length[i])){
			cout << "Congratulations! You pass the check." << endl;
			cout << "Speedup: " << (float)intervalJoinCPUExecTime / intervalJoinGPUExecTime << endl;
		}
		else
			cout << "Sorry! Your result is wrong." << endl;
		
		ending(i);
	}
	
	fclose(fpA);
	fclose(fpB);

	return 0;
}
