// gcc -pthread 1.c -o 1.out -fsanitize=address -ggdb  && ./1.out 
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>
#define MAX_STR_LEN 1024

#define BLK "\e[0;30m"
#define RED "\e[0;31m"
#define GRN "\e[0;32m"
#define YEL "\e[0;33m"
#define BLU "\e[0;34m"
#define MAG "\e[0;35m"
#define CYN "\e[0;36m"
#define WHT "\e[0;37m"

#define CRESET "\e[0m"

typedef struct {
	// pthread_t t_id;
	int i;
	int B,K,N;
	char** coffee_name;
	int* coffee_time;
	char** cust_coffee;
	int* cust_time;
	int* cust_tol;
	int* cust_status;
} CafeInfo;

pthread_t *producers;
pthread_t *consumers;

sem_t* prod_start, *prod_comp;
sem_t* cons_start, *cons_comp;
sem_t con_lock, status_lock;
int all_finished;
int ticks;

int coffees_wasted;
sem_t cof_was_lock;

int tot_wait_time;
sem_t wait_lock;

void* producer(void* _cInfo ){
	CafeInfo* cInfo = (CafeInfo*) _cInfo;
	int b_idx = 0;
	pthread_t t_id = pthread_self();
	while (producers[b_idx] != t_id) b_idx++;
	// printf("Barrista %d\n", b_idx);
	int job = -1;
	int job_cust = 0;
	int job_ticks= 0;
	while (1){
		sem_wait(&prod_start[b_idx]);
		if (all_finished) return 0;
		if (job!= -1){
			job_ticks--;
			
			// if job_ticks == time for coffee
			if (job_ticks == 0)
			{
				// set status to done 
				sem_wait(&status_lock);
				if (cInfo->cust_status[job_cust] != 3) // If customer didnt already leave
					cInfo->cust_status[job_cust] = 4;
				else{ // Coffee wasted
					sem_wait(&cof_was_lock);
					coffees_wasted++;
					sem_post(&cof_was_lock);
				}
				sem_post(&status_lock);
				// acquire con_lock, print done, release con_lock
				sem_wait(&con_lock);
				printf(BLU"Barista %d completes the order of Customer %d at %d second(s)\n"CRESET, b_idx+1, job_cust+1, ticks);
				sem_post(&con_lock);
				job = -1;
			} 
		}
		else{
			// Need to find new consumer
			// get status_lock,	find available consumer, set status to making, release status lock 
			// get con_lock, print started making, release con_lock
			sem_wait(&status_lock);
			for (int i = 0; i < cInfo->N; i++)
			{
				if (cInfo->cust_status[i] == 1){
					cInfo->cust_status[i] = 2;
					for (int j = 0; j < cInfo->K; j++)
					{
						if (strcmp(cInfo->coffee_name[j], cInfo->cust_coffee[i]) == 0){
							job = j;
							job_ticks = cInfo->coffee_time[j];
							break;
						}
					}
					job_cust = i;
					sem_wait(&con_lock);
					printf(CYN"Barista %d begins preparing the order of customer %d at %d second(s) (%d)\n"CRESET, b_idx+1, job_cust+1, ticks, job_ticks);
					
					sem_post(&con_lock);
					break;
				}
			}
			sem_post(&status_lock);
		}
		sem_post(&prod_comp[b_idx]);
	}
}


void* consumer(void* _cInfo ){
	CafeInfo* cInfo = (CafeInfo*) _cInfo;
	int self_status = 0; // 0 =  not ordered, 1 = ordered,  2 = done
	int c_idx = 0;
	pthread_t t_id = pthread_self();
	while (consumers[c_idx] != t_id) c_idx++;
	
	int wait_time = 0;

	while(1){
		sem_wait(&cons_start[c_idx]);
		// if (c_idx == 2){

			// printf("\t<%d>%d %d %d\n",c_idx, ticks, self_status, wait_time);
		// }
		if (all_finished)
			return 0;

		if (ticks< cInfo->cust_time[c_idx]){
			sem_post(&cons_comp[c_idx]);
			continue;
		}
		if (self_status == 2){
			sem_post(&cons_comp[c_idx]);
			continue;
		}

		// if ticks >= start ticks
		// if self_status = not ordered
		if (self_status == 0)
		{
			// set status to ordered
			// get  con_lock, print status, release con_lock
			sem_wait(&status_lock);
			cInfo->cust_status[c_idx] = 1;
			self_status = 1;
			sem_post(&status_lock);
			sem_wait(&con_lock);
			printf("Customer %d arrives at %d second(s)\n"YEL"Customer %d orders an %s\n"CRESET, c_idx +1, ticks, c_idx+1, cInfo->cust_coffee[c_idx]);
			sem_post(&con_lock);
			wait_time = cInfo->cust_tol[c_idx];
			sem_post(&cons_comp[c_idx]);
			continue;
		}
		// if status = done
		if (cInfo->cust_status[c_idx] == 4)
		{
			// set status to left w/ order
			// print status

			sem_wait(&status_lock);
			cInfo->cust_status[c_idx] = 5; 
			sem_post(&status_lock);
			self_status = 2;
			sem_wait(&con_lock);
			printf(GRN"Customer %d leaves with their order at %d second(s)\n"CRESET, c_idx +1, ticks);
			sem_post(&con_lock);

		}
		// if status = making || ordered
		if (cInfo->cust_status[c_idx] == 1 || cInfo->cust_status[c_idx] == 2)
		{
			wait_time -- ;


			// if wait not done,
			if (wait_time>= 0)
			{
				sem_wait(&wait_lock);
				tot_wait_time++;
				sem_post(&wait_lock);
				sem_post(&cons_comp[c_idx]);
				continue;	
			} 
			// else (past waiting time )
			else
			{

				// set status to left, 
				// print,
				// return
				sem_wait(&status_lock);
				cInfo->cust_status[c_idx] = 3; 
				sem_post(&status_lock);
				self_status = 2;
				sem_wait(&con_lock);
				printf(RED"Customer %d leaves without their order at %d second(s)\n"CRESET, c_idx +1, ticks);
				sem_post(&con_lock);

			}
		}

		sem_post(&cons_comp[c_idx]);
	}	
}

void* tick_sync(void* _cInfo ){
	CafeInfo* cInfo = (CafeInfo*) _cInfo;
	while (1){
		// printf(">%d\n", ticks);

		// if all status is left (w or w/o), set all done
		int is_all_finished = 1;
		for (int i = 0; i < cInfo->N; i++)
		{
			if (cInfo->cust_status[i] != 3 && cInfo->cust_status[i] != 5){
				is_all_finished = 0;
				break;
			}
		}
		if (is_all_finished){
			all_finished = 1;
			for (int i = 0; i < cInfo->B; i++)
			{
				sem_post(&prod_start[i]);
			}
			for (int i = 0; i < cInfo->N; i++)
			{
				sem_post(&cons_start[i]);
			}
			return 0;
		}
		
		
		// Start all producers
		for (int i = 0; i < cInfo->B; i++)
		{
			sem_post(&prod_start[i]);
		}
		// wait for all producers (prod_comp)
		for (int i = 0; i < cInfo->B; i++)
		{
			sem_wait(&prod_comp[i]);
		}
		
		// Start all consumers
		for (int i = 0; i < cInfo->N; i++)
		{
			sem_post(&cons_start[i]);
		}
		// wait for all consumers (cons_comp)
		for (int i = 0; i < cInfo->N; i++)
		{
			sem_wait(&cons_comp[i]);
		}
		
		// increment tick 

		ticks++;
	}
}



int main(void){
	
	int i,err;

	srand(time(NULL));

    int B, K, N; scanf("%d %d %d", &B, &K, &N);

    char* coffee_name[K];
    int coffee_time[K]; 
    for (int i = 0; i < K; i++)
    {
		coffee_name[i] = malloc(MAX_STR_LEN*sizeof(char));
        scanf("%s %d", coffee_name[i], &coffee_time[i]);
    }

    char* cust_coffee[N];
    int cust_time[N];
    int cust_tol[N];
    for (int i = 0; i < N; i++)
    {
        int temp;
		cust_coffee[i] = malloc(MAX_STR_LEN*sizeof(char));

        scanf("%d %s %d %d", &temp, cust_coffee[i], &cust_time[i], &cust_tol[i]);
    }
    


	CafeInfo cInfo;
	cInfo.B = B;
	cInfo.K = K;
	cInfo.N = N;
	cInfo.coffee_name = malloc(K*sizeof(char*));
	for (int i = 0; i < K; i++)
	{
		cInfo.coffee_name[i] = malloc((strlen(coffee_name[i])+1)*sizeof(char));
		strcpy(cInfo.coffee_name[i], coffee_name[i]);
	}
	cInfo.coffee_time = malloc(K*sizeof(int));
	memcpy(cInfo.coffee_time, coffee_time, K*sizeof(int) );
	
	cInfo.cust_coffee = malloc(N*sizeof(char*));
	for (int i = 0; i < N; i++)
	{
		cInfo.cust_coffee[i] = malloc((strlen(cust_coffee[i])+1)*sizeof(char));
		strcpy(cInfo.cust_coffee[i], cust_coffee[i]);
	}
	cInfo.cust_time = malloc(N*sizeof(int));
	memcpy(cInfo.cust_time, cust_time, N*sizeof(int) );

	cInfo.cust_tol = malloc(N*sizeof(int));
	memcpy(cInfo.cust_tol, cust_tol, N*sizeof(int) );
	
	cInfo.cust_status = malloc(N*sizeof(int));
	for (int i = 0; i < N; i++)
	{
		cInfo.cust_status[i] = 0;
	}
	
	// 0 = cust not arrived
	// 1 = cust arrived and set order
	// 2 = barrista making order
	// 3 = cust left w/o order
	// 4 = barrista done 
	// 5 = cust left with order

	producers= malloc(B*sizeof(pthread_t));
	consumers= malloc(N*sizeof(pthread_t));
	prod_start = malloc(B*sizeof(sem_t));
	prod_comp = malloc(B*sizeof(sem_t));
	cons_start = malloc(N*sizeof(sem_t));
	cons_comp = malloc(N*sizeof(sem_t));

	for (int i = 0; i < B; i++)
	{
		sem_init(&prod_start[i], 0 ,0);
		sem_init(&prod_comp[i], 0 ,0);

	}
	for (int i = 0; i < N; i++)
	{
		sem_init(&cons_start[i], 0 ,0);
		sem_init(&cons_comp[i], 0 ,0);

	}
	
	sem_init(&status_lock, 0, 1);
	sem_init(&con_lock, 0, 1);

	sem_init(&cof_was_lock, 0, 1);
	coffees_wasted = 0;

	sem_init(&wait_lock, 0, 1);
	tot_wait_time = 0;

	for(i=0;i<B;i++){
		err = pthread_create(producers+i,NULL,&producer,&cInfo);
		// printf("> %d %lu\n", i, *(producers+i) );
		if(err != 0){
			printf("Error creating producer %d: %s\n",i+1,strerror(err));
		}else{
			// printf("Successfully created producer %d\n",i+1);
		}
	}

	for(i=0;i<N;i++){
		err = pthread_create(consumers+i,NULL,&consumer,&cInfo);
		if(err != 0){
			printf("Error creating consumer %d: %s\n",i+1,strerror(err));
		}else{
			// printf("Successfully created consumer %d\n",i+1);
		}
	}
	pthread_t sync_thr;
	pthread_create(&sync_thr, NULL, &tick_sync, &cInfo);
	for(i=0;i<B;i++){
		pthread_join(*(producers+i),NULL);
	}
	for(i=0;i<N;i++){
		pthread_join(*(consumers+i),NULL);
	}
	pthread_join(sync_thr, NULL);

	int sum_times = 0;
	for (int i = 0; i < N; i++)
	{
		for (int j = 0; j < K; j++)
		{
			if (strcmp(cust_coffee[i], coffee_name[j]) == 0){
				sum_times += coffee_time[j];
				break;
			}
		}
		
	}
	

	printf("Coffees Wasted: %d \n", coffees_wasted);
	printf("Average Wait time %.2f\n", ((float) tot_wait_time)/N);
	printf("Minimum Wait time %.2f\n", ((float) sum_times)/N);

	return 0;
}